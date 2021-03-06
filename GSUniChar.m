/*
   Copyright (C) 2001,2006 Free Software Foundation, Inc.

   Written by:  Jonathan Gapen  <jagapen@home.com>
   Date: March 2001
   Update by: Richard Frith-Macdonald <rfm@gnu.org>

   This file is part of the GNUstep Unicode Character Set Data Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "GSUniChar.h"

#define NUM_CATEGORIES	((int)(UCDSymbolOtherCategory) + 1)

struct UCDCategoryMap
{
  NSString *categoryString;
  UCDGeneralCategory category;
};

struct UCDCategoryMap categoryMap[NUM_CATEGORIES] = {
  { @"Cc", UCDControlCategory },
  { @"Cf", UCDFormatCategory },
  { @"Cn", UCDNotAssignedCategory },
  { @"Co", UCDPrivateUseCategory },
  { @"Cs", UCDSurrogateCategory },
  { @"Ll", UCDLetterLowercaseCategory },
  { @"Lm", UCDLetterModifierCategory },
  { @"Lo", UCDLetterOtherCategory },
  { @"Lt", UCDLetterTitlecaseCategory },
  { @"Lu", UCDLetterUppercaseCategory },
  { @"Mc", UCDMarkSpacingCombiningCategory },
  { @"Me", UCDMarkEnclosingCategory },
  { @"Mn", UCDMarkNonSpacingCategory },
  { @"Nd", UCDNumberDecimalDigitCategory },
  { @"Nl", UCDNumberLetterCategory },
  { @"No", UCDNumberOtherCategory },
  { @"Pc", UCDPunctuationConnectorCategory },
  { @"Pd", UCDPunctuationDashCategory },
  { @"Pe", UCDPunctuationCloseCategory },
  { @"Pf", UCDPunctuationFinalQuoteCategory },
  { @"Pi", UCDPunctuationInitialQuoteCategory },
  { @"Po", UCDPunctuationOtherCategory },
  { @"Ps", UCDPunctuationOpenCategory },
  { @"Sc", UCDSymbolCurrencyCategory },
  { @"Sk", UCDSymbolModifierCategory },
  { @"Sm", UCDSymbolMathCategory },
  { @"So", UCDSymbolOtherCategory },
  { @"Zl", UCDSeparatorLineCategory },
  { @"Zp", UCDSeparatorParagraphCategory },
  { @"Zs", UCDSeparatorSpaceCategory }
};

@implementation GSUniChar

static NSMutableDictionary	*firstInRange = nil;

+ (void) initialize
{
  firstInRange = [NSMutableDictionary new];
}

- (id) initWithArray: (NSArray *)anArray
{
  NSScanner *scanner;
  unsigned unsignedValue;
  NSString *genCatStr, *aString;
  int i;

  [super init];

  _numberOfCharacters = 1;
  // character value
  scanner = [NSScanner scannerWithString: [anArray objectAtIndex: 0]];
  [scanner scanHexInt: &unsignedValue];
  if (unsignedValue < MAX_UNICHAR)
    {
      _character = unsignedValue;
    }
  else
    {
      [self dealloc];
      return nil;
    }

  /* If this is actually the end of a range ... look up the first value in
   * the range, adjust the range length, and return the first value.
   */
  aString = [anArray objectAtIndex: 1];
  if ([aString hasSuffix: @" Last>"] == YES)
    {
      GSUniChar	*found;

      aString = [[aString substringToIndex: [aString length] - 5]
        stringByAppendingString: @"First>"];
      found = [firstInRange objectForKey: aString];
      if (found != nil)
        {
	  found->_numberOfCharacters = _character - found->_character;
	}
      RETAIN(found);
      [firstInRange removeObjectForKey: aString];
      RELEASE(self);
      return found;
    }

  _name = [aString copy];
  if ([_name hasSuffix: @" First>"] == YES)
    {
      _isRange = YES;
      [firstInRange setObject: self forKey: _name];
    }

  // general category
  _genCat = UCDNotAssignedCategory;
  genCatStr = [anArray objectAtIndex: 2];

  for (i = 0; i < NUM_CATEGORIES; i++)
    {
      if ([genCatStr isEqualToString: categoryMap[i].categoryString])
        {
          _genCat = categoryMap[i].category;
          break;
        }
    }

  // combining classes
  // FIXME - implement

  // bidirectional category
  // FIXME - implement
  _biDirCat = 0;

  // decomposition mapping
  _decomp = [[anArray objectAtIndex: 5] copy];

  // decimal digit value
  aString = [anArray objectAtIndex: 6];
  if (aString != nil)
    {
      // NSString's intValue returns 0 if the receiver doesn't contain
      // a decimal integer value, but 0 is a valid decimal digit.
      scanner = [NSScanner scannerWithString: aString];
      if ([scanner scanInt: &_decimalValue] == NO)
        _decimalValue = -1;
    }

  // digit value
  aString = [anArray objectAtIndex: 7];
  if (aString != nil)
    {
      scanner = [NSScanner scannerWithString: aString];
      if ([scanner scanInt: &_digitValue] == NO)
        _digitValue = -1;
    }

  // numeric value

  // mirrored
  if ([[anArray objectAtIndex: 9] isEqualToString: @"Y"])
    _mirrored = YES;
  else
    _mirrored = NO;

  // Unicode 1.0 name
  _oldname = [[anArray objectAtIndex: 10] copy];

  // 10646 comment field
  _comment = [[anArray objectAtIndex: 11] copy];

  // uppercase mapping
  _uppercase = unsignedValue = 0;
  aString = [anArray objectAtIndex: 12];
  if (aString != nil)
    {
      scanner = [NSScanner scannerWithString: aString];
      [scanner scanHexInt: &unsignedValue];
      if (unsignedValue < MAX_UNICHAR)
        _uppercase = (UTF32Char)unsignedValue;
    }

  // lowercase mapping
  _lowercase = unsignedValue = 0;
  aString = [anArray objectAtIndex: 13];
  if (aString != nil)
    {
      scanner = [NSScanner scannerWithString: aString];
      [scanner scanHexInt: &unsignedValue];
      if (unsignedValue < MAX_UNICHAR)
        _lowercase = (UTF32Char)unsignedValue;
    }

  // titlecase mapping
  _titlecase = unsignedValue = 0;
  aString = [anArray objectAtIndex: 14];
  if (aString != nil)                  
    {               
      scanner = [NSScanner scannerWithString: aString];
      [scanner scanHexInt: &unsignedValue];
      if (unsignedValue < MAX_UNICHAR)
        _titlecase = (UTF32Char)unsignedValue;
    }

  return self;
}

- (id) initWithString: (NSString *)line
{
  NSArray *fields = [line componentsSeparatedByString:@";"];

  return [self initWithArray: fields];
}

- (void) dealloc
{
  if (_name)
    [_name release];
  if (_decomp)
    [_decomp release];

  [super dealloc];
}

- (UTF32Char) character
{
  return _character;
}

- (NSRange) range
{
  return NSMakeRange(_character, _numberOfCharacters);
}

- (NSString *) name
{
  return _name;
}

- (UCDGeneralCategory) generalCategory
{
  return _genCat;
}

- (UCDCanonicalCombiningClass) canonicalCombiningClass
{
  return _combiningClass;
}

- (UCDBidirectionalCategory) bidirectionalCategory
{
  return _biDirCat;
}

- (NSString *) decompositionMapping
{
  return _decomp;
}

- (int) decimalDigitValue
{
  return _decimalValue;
}

- (int) digitValue
{
  return _digitValue;
}

- (NSDecimal) numericValue
{
  return _numericValue;
}

- (BOOL) isMirrored
{
  return _mirrored;
}

- (BOOL) isRange
{
  return _isRange;
}

- (NSString *) oldName
{
  return _oldname;
}

- (NSString *) comment
{
  return _comment;
}

- (UTF32Char) uppercaseMapping
{
  return _uppercase;
}

- (UTF32Char) lowercaseMapping
{
  return _lowercase;
}

- (UTF32Char) titlecaseMapping
{
  return _titlecase;
}

@end
