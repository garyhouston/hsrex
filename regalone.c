#ifdef REGEX_WCHAR

#include "regcustom.h"



/*
 *----------------------------------------------------------------------
 *
 * Tcl_DStringInit --
 *
 *	Initializes a dynamic string, discarding any previous contents of the
 *	string (Tcl_DStringFree should have been called already if the dynamic
 *	string was previously in use).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The dynamic string is initialized to be empty.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DStringInit(
    Tcl_DString *dsPtr)		/* Pointer to structure for dynamic string. */
{
    dsPtr->string = dsPtr->staticSpace;
    dsPtr->length = 0;
    dsPtr->spaceAvl = TCL_DSTRING_STATIC_SIZE;
    dsPtr->staticSpace[0] = '\0';
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_DStringSetLength --
 *
 *	Change the length of a dynamic string. This can cause the string to
 *	either grow or shrink, depending on the value of length.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The length of dsPtr is changed to length and a null byte is stored at
 *	that position in the string. If length is larger than the space
 *	allocated for dsPtr, then a panic occurs.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DStringSetLength(
    Tcl_DString *dsPtr,		/* Structure describing dynamic string. */
    int length)			/* New length for dynamic string. */
{
    int newsize;

    if (length < 0) {
	length = 0;
    }
    if (length >= dsPtr->spaceAvl) {
	/*
	 * There are two interesting cases here. In the first case, the user
	 * may be trying to allocate a large buffer of a specific size. It
	 * would be wasteful to overallocate that buffer, so we just allocate
	 * enough for the requested size plus the trailing null byte. In the
	 * second case, we are growing the buffer incrementally, so we need
	 * behavior similar to Tcl_DStringAppend. The requested length will
	 * usually be a small delta above the current spaceAvl, so we'll end
	 * up doubling the old size. This won't grow the buffer quite as
	 * quickly, but it should be close enough.
	 */

	newsize = dsPtr->spaceAvl * 2;
	if (length < newsize) {
	    dsPtr->spaceAvl = newsize;
	} else {
	    dsPtr->spaceAvl = length + 1;
	}
	if (dsPtr->string == dsPtr->staticSpace) {
	    char *newString = ckalloc((unsigned) dsPtr->spaceAvl);

	    memcpy(newString, dsPtr->string, (size_t) dsPtr->length);
	    dsPtr->string = newString;
	} else {
	    dsPtr->string = (char *) ckrealloc((void *) dsPtr->string,
		    (size_t) dsPtr->spaceAvl);
	}
    }
    dsPtr->length = length;
    dsPtr->string[length] = 0;
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_DStringFree --
 *
 *	Frees up any memory allocated for the dynamic string and reinitializes
 *	the string to an empty state.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The previous contents of the dynamic string are lost, and the new
 *	value is an empty string.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DStringFree(
    Tcl_DString *dsPtr)		/* Structure describing dynamic string. */
{
    if (dsPtr->string != dsPtr->staticSpace) {
	ckfree(dsPtr->string);
    }
    dsPtr->string = dsPtr->staticSpace;
    dsPtr->length = 0;
    dsPtr->spaceAvl = TCL_DSTRING_STATIC_SIZE;
    dsPtr->staticSpace[0] = '\0';
}



/*
 * Unicode characters less than this value are represented by themselves in
 * UTF-8 strings.
 */

#define UNICODE_SELF	0x80


/*
 *---------------------------------------------------------------------------
 *
 * Tcl_UniCharToUtf --
 *
 *	Store the given Tcl_UniChar as a sequence of UTF-8 bytes in the
 *	provided buffer. Equivalent to Plan 9 runetochar().
 *
 * Results:
 *	The return values is the number of bytes in the buffer that were
 *	consumed.
 *
 * Side effects:
 *	None.
 *
 *---------------------------------------------------------------------------
 */

INLINE int
Tcl_UniCharToUtf(
    int ch,			/* The Tcl_UniChar to be stored in the
				 * buffer. */
    char *buf)			/* Buffer in which the UTF-8 representation of
				 * the Tcl_UniChar is stored. Buffer must be
				 * large enough to hold the UTF-8 character
				 * (at most TCL_UTF_MAX bytes). */
{
    if ((ch > 0) && (ch < UNICODE_SELF)) {
	buf[0] = (char) ch;
	return 1;
    }
    if (ch >= 0) {
	if (ch <= 0x7FF) {
	    buf[1] = (char) ((ch | 0x80) & 0xBF);
	    buf[0] = (char) ((ch >> 6) | 0xC0);
	    return 2;
	}
	if (ch <= 0xFFFF) {
	three:
	    buf[2] = (char) ((ch | 0x80) & 0xBF);
	    buf[1] = (char) (((ch >> 6) | 0x80) & 0xBF);
	    buf[0] = (char) ((ch >> 12) | 0xE0);
	    return 3;
	}

#if TCL_UTF_MAX > 3
	if (ch <= 0x1FFFFF) {
	    buf[3] = (char) ((ch | 0x80) & 0xBF);
	    buf[2] = (char) (((ch >> 6) | 0x80) & 0xBF);
	    buf[1] = (char) (((ch >> 12) | 0x80) & 0xBF);
	    buf[0] = (char) ((ch >> 18) | 0xF0);
	    return 4;
	}
	if (ch <= 0x3FFFFFF) {
	    buf[4] = (char) ((ch | 0x80) & 0xBF);
	    buf[3] = (char) (((ch >> 6) | 0x80) & 0xBF);
	    buf[2] = (char) (((ch >> 12) | 0x80) & 0xBF);
	    buf[1] = (char) (((ch >> 18) | 0x80) & 0xBF);
	    buf[0] = (char) ((ch >> 24) | 0xF8);
	    return 5;
	}
	if (ch <= 0x7FFFFFFF) {
	    buf[5] = (char) ((ch | 0x80) & 0xBF);
	    buf[4] = (char) (((ch >> 6) | 0x80) & 0xBF);
	    buf[3] = (char) (((ch >> 12) | 0x80) & 0xBF);
	    buf[2] = (char) (((ch >> 18) | 0x80) & 0xBF);
	    buf[1] = (char) (((ch >> 24) | 0x80) & 0xBF);
	    buf[0] = (char) ((ch >> 30) | 0xFC);
	    return 6;
	}
#endif
    }

    ch = 0xFFFD;
    goto three;
}

/*
 *---------------------------------------------------------------------------
 *
 * Tcl_UniCharToUtfDString --
 *
 *	Convert the given Unicode string to UTF-8.
 *
 * Results:
 *	The return value is a pointer to the UTF-8 representation of the
 *	Unicode string. Storage for the return value is appended to the end of
 *	dsPtr.
 *
 * Side effects:
 *	None.
 *
 *---------------------------------------------------------------------------
 */

char *
Tcl_UniCharToUtfDString(
    const Tcl_UniChar *uniStr,	/* Unicode string to convert to UTF-8. */
    int uniLength,		/* Length of Unicode string in Tcl_UniChars
				 * (must be >= 0). */
    Tcl_DString *dsPtr)		/* UTF-8 representation of string is appended
				 * to this previously initialized DString. */
{
    const Tcl_UniChar *w, *wEnd;
    char *p, *string;
    int oldLength;

    /*
     * UTF-8 string length in bytes will be <= Unicode string length *
     * TCL_UTF_MAX.
     */

    oldLength = Tcl_DStringLength(dsPtr);
    Tcl_DStringSetLength(dsPtr, (oldLength + uniLength + 1) * TCL_UTF_MAX);
    string = Tcl_DStringValue(dsPtr) + oldLength;

    p = string;
    wEnd = uniStr + uniLength;
    for (w = uniStr; w < wEnd; ) {
	p += Tcl_UniCharToUtf(*w, p);
	w++;
    }
    Tcl_DStringSetLength(dsPtr, oldLength + (p - string));

    return string;
}

#endif		/* REGEX_WCHAR	*/
