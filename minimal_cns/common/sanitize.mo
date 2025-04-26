import Text "mo:base/Text";
import Char "mo:base/Char";


module {
  public func trimWhitespace(text : Text) : Text {
    Text.trimEnd(Text.trimStart(text, #char(' ')), #char(' '));
  };

  public func isAlphanumeric(char: Char) : Bool {
    ('a' <= char and char <= 'z')
    or
    ('A' <= char and char <= 'Z')
    or
    ('0' <= char and char <= '9')
  };

  public func isAlphaNumericOr(char: Char, f : (Char) -> Bool) : Bool {
    isAlphanumeric(char) or f(char)
  };
}