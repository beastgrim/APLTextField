//
//  APLTextField.m
//
//  Created by Michael Kamphausen on 06.05.13.
//  Copyright (c) 2013 apploft GmbH. All rights reserved.
//

#import "APLTextField.h"

NSString * const APLTextFieldTextDidChangeNotification = @"APLTextFieldTextDidChangeNotification";

@interface APLTextField () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, assign) BOOL hasPicker;
@property (nonatomic, strong) UIColor* normalTextColor;
@property (nonatomic, retain) UIDatePicker* datePicker;

@end


@implementation APLTextField
@synthesize pickerTextColor;
@synthesize pickerBackgroundColor;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // workaround for a bug in Interface Builder not localizing the placeholder property for UITextField subclasses
        self.placeholder = NSLocalizedString(self.placeholder, nil);
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - custom getters and setters

- (void)setPickerOptions:(NSArray *)pickerOptions {
    if (self.selectNonePickerOption && (![pickerOptions count] || ([pickerOptions count] && ![self.selectNonePickerOption isEqualToString:pickerOptions[0]]))) {
        _pickerOptions = [@[self.selectNonePickerOption] arrayByAddingObjectsFromArray:pickerOptions];
    } else {
        _pickerOptions = pickerOptions;
    }
    self.hasPicker = YES;
    
    if (!self.pickerView) {
        self.pickerView = [UIPickerView new];
        CGRect frame = self.pickerView.frame;
        frame.origin.y = [UIScreen mainScreen].bounds.size.height;
        self.pickerView.frame = frame;
        self.pickerView.showsSelectionIndicator = YES;
        self.pickerView.delegate = self;
        self.pickerView.dataSource = self;
        if (self.pickerBackgroundColor) {
            self.pickerView.backgroundColor = self.pickerBackgroundColor;
        }
        if (self.pickerTextColor) {
            [self.datePicker setValue:pickerTextColor forKeyPath:@"textColor"];
        } else {
            [self.datePicker setValue:[UIColor redColor] forKeyPath:@"textColor"];
        }
    }
    self.inputView = self.pickerView;
    [self.pickerView reloadAllComponents];
    [self setAndSelectText:self.text];
    
    for (UIGestureRecognizer* gestureRecognizer in self.gestureRecognizers) {
        [self disableLongPressGestureRecognizer:gestureRecognizer];
    }
}

- (void)setSelectNonePickerOption:(NSString *)selectNonePickerOption {
    NSString* oldSelectNonePickerOption = _selectNonePickerOption;
    _selectNonePickerOption = selectNonePickerOption;
    if (self.pickerOptions) {
        if (oldSelectNonePickerOption && [self.pickerOptions count] && [oldSelectNonePickerOption isEqualToString:self.pickerOptions[0]]) {
            self.pickerOptions = [self.pickerOptions subarrayWithRange:NSMakeRange(1, [self.pickerOptions count] - 1)];
        } else {
            self.pickerOptions = self.pickerOptions;
        }
    }
}

- (void)setHasDatePicker:(BOOL)hasDatePicker {
    _hasDatePicker = hasDatePicker;
    self.hasPicker = hasDatePicker;
    
    if (hasDatePicker) {
        self.datePicker = [UIDatePicker new];
        CGRect frame = self.datePicker.frame;
        frame.origin.y = [UIScreen mainScreen].bounds.size.height;
        self.datePicker.frame = frame;
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        [self.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
        self.inputView = self.datePicker;
        
        if (self.pickerBackgroundColor) {
            self.datePicker.backgroundColor = self.pickerBackgroundColor;
        }
        
        if (self.pickerTextColor) {
            [self.datePicker setValue:pickerTextColor forKeyPath:@"textColor"];
        } else {
            [_datePicker setValue:[UIColor blackColor] forKeyPath:@"textColor"];
        }
    }
}

- (void)setAndSelectText:(NSString*)text {
    self.text = text;
    if (self.hasPicker) {
        NSUInteger index = [self.pickerOptions indexOfObject:text];
        if (index != NSNotFound) {
            [self.pickerView selectRow:index inComponent:0 animated:NO];
        } else {
            self.text = nil;
        }
    }
}

- (void)setAndSelectDate:(NSDate*)date {
    self.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    if (date) {
        [self.datePicker setDate:date];
    }
}

- (NSDate*)getDate {
    return [self.text length] ? [self.datePicker date] : nil;
}

- (void)setLeftImage:(NSString*)name {
    self.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:name]];
    self.leftView.frame = CGRectMake(0., 0., 30., 30.);
    self.leftView.contentMode = UIViewContentModeCenter;
    self.leftViewMode = UITextFieldViewModeAlways;
}

- (BOOL)hasLeftView {
    return self.leftView && (self.leftViewMode != UITextFieldViewModeNever);
}

#pragma mark - Customize
//-(void)setPickerBackgroundColor:(UIColor *)pickerBackgroundColor {
////    self.pickerBackgroundColor = pickerBackgroundColor;
//    if (self.datePicker) {
//        self.datePicker.backgroundColor = self.pickerBackgroundColor;
//    } else {
//        self.pickerView.backgroundColor = self.pickerBackgroundColor;
//    }
//}
//-(void)setPickerTextColor:(UIColor *)pickerTextColor {
////    self.pickerTextColor = pickerTextColor;
////    if (self.datePicker) {
//        Log(@"setDatePickerTextColor %@", pickerTextColor);
//        [self.datePicker setValue:[UIColor redColor] forKeyPath:@"textColor"];
////    } else {
//        [self.pickerView setValue:[UIColor redColor] forKeyPath:@"textColor"];
////    }
//}
#pragma mark - overridden methods

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGFloat x = bounds.origin.x + 8;
    CGFloat width = bounds.size.width - 16;
    if ([self hasLeftView]) {
        CGFloat leftViewWidth = self.leftView.frame.origin.x + self.leftView.frame.size.width;
        width = width - (leftViewWidth - x);
        x = leftViewWidth;
    }
    if (self.rightView && (self.rightViewMode != UITextFieldViewModeNever)) {
        width = self.rightView.frame.origin.x - x;
    }
    return CGRectMake(x, bounds.origin.y + 10, width, bounds.size.height - 18);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    return self.hasPicker ? CGRectZero : [super caretRectForPosition:position];
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
    return self.hasPicker ? nil : [super selectionRectsForRange:range];
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    [self disableLongPressGestureRecognizer:gestureRecognizer];
    [super addGestureRecognizer:gestureRecognizer];
}

- (void)disableLongPressGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
    // prevent magnifying glass from being displayed
    if (self.hasPicker && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        gestureRecognizer.enabled = NO;
    }
}

- (BOOL)becomeFirstResponder {
    BOOL wasEditingBefore = self.editing;
    BOOL canBecomeFirstResponder = [super becomeFirstResponder];
    if (self.hasPicker && canBecomeFirstResponder && !wasEditingBefore) {
        self.normalTextColor = self.textColor;
        self.textColor = [UIColor lightGrayColor];
        if (![self.text length] && ![self.selectNonePickerOption length] && [self.pickerOptions count]) {
            [self.pickerView selectRow:self.selectedPickerOption inComponent:0 animated:NO];
            [self pickerView:self.pickerView didSelectRow:self.selectedPickerOption inComponent:0];
        }
    }
    return canBecomeFirstResponder;
}

- (BOOL)resignFirstResponder {
    BOOL canResignFirstResponder = [super resignFirstResponder];
    if (canResignFirstResponder && self.hasPicker) {
        self.textColor = self.normalTextColor;
    }
    return canResignFirstResponder;
}

- (void)drawPlaceholderInRect:(CGRect)rect {
    [[UIColor lightGrayColor] setFill];
    //    [self.placeholder drawInRect:rect withFont:self.font];
    [self.placeholder drawInRect:rect withAttributes:@{NSFontAttributeName: self.font}];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.hasPicker) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //    if ([self hasLeftView]) {
    //        CGRect frame = self.leftView.frame;
    //        frame.size = CGSizeMake(self.frame.size.height, self.frame.size.height);
    //        self.leftView.frame = frame;
    //    }
}

#pragma mark - text editing events

- (void)textChanged:(NSNotification *)notification {
    if (self.maxCharacters > 0) {
        if (self.maxCharacters < [self.text length]) {
            self.text = [self.text substringToIndex:self.maxCharacters];
        }
    }
}

#pragma mark - UIDatePicker action

- (void)dateChanged:(id)sender {
    self.text = [NSDateFormatter localizedStringFromDate:[self.datePicker date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    [[NSNotificationCenter defaultCenter] postNotificationName:APLTextFieldTextDidChangeNotification object:self];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return row < [self.pickerOptions count] ? self.pickerOptions[row] : @"";
}
//- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    NSString *title = row < [self.pickerOptions count] ? self.pickerOptions[row] : @"";
//    if (self.pickerTextColor == nil) {
//        self.pickerTextColor = [UIColor blackColor];
//    }
//    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:self.pickerTextColor}];
//
//    return attString;
//}
//-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
//    // create attributed string
//    NSString *title = row < [self.pickerOptions count] ? self.pickerOptions[row] : @""; if (!title) title = @"error";
//    if (!pickerTextColor) {
//        pickerTextColor = [UIColor blackColor];
//    }
//    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
//
//    // add the string to a label's attributedText property
//    UILabel *labelView = [UILabel new];
//    labelView.attributedText = attString;
//    labelView.textAlignment = NSTextAlignmentCenter;
//    labelView.font = [labelView.font fontWithSize:20];
//
//    return labelView;
//}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString* value = [self objectAtSafeIndex:row fromArray:self.pickerOptions];
    if (value == nil) return;
    
    NSRange range = {0, [self.text length]};
    self.text = [value isEqualToString:self.selectNonePickerOption] ? nil : value;
    if (self.delegate) {
        [self.delegate textField:self shouldChangeCharactersInRange:range replacementString:self.text];
    }
    self.selectedPickerOption = row;
    [[NSNotificationCenter defaultCenter] postNotificationName:APLTextFieldTextDidChangeNotification object:self];
}

- (id)objectAtSafeIndex:(NSInteger)index fromArray:(NSArray*)array {
    return [array count] ? array[MIN(index, MAX(0, [array count] - 1))] : nil;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return MAX([self.pickerOptions count], 1);
}

@end
