<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Utilities for strings

<a id="chr"></a>

## chr

<pre>
chr(<a href="#chr-i">i</a>)
</pre>

returns a string encoding a codepoint

chr returns a string that encodes the single Unicode code
point whose value is specified by the integer `i`


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="chr-i"></a>i |  position of the character   |  none |

**RETURNS**

unicode string of the position


<a id="hex"></a>

## hex

<pre>
hex(<a href="#hex-number">number</a>)
</pre>

Format integer to hexdecimal representation

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="hex-number"></a>number |  number to format   |  none |

**RETURNS**

hexdecimal representation of the number argument


<a id="ord"></a>

## ord

<pre>
ord(<a href="#ord-c">c</a>)
</pre>

returns the codepoint of a character

ord(c) returns the integer value of the sole Unicode code point
encoded by the string `c`.

If `c` does not encode exactly one Unicode code point, `ord` fails.
Each invalid code within the string is treated as if it encodes the
Unicode replacement character, U+FFFD.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ord-c"></a>c |  character whose codepoint to be returned.   |  none |

**RETURNS**

codepoint of `c` argument.


