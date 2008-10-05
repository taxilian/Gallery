@interface CQPreferencesTextCell : UITableViewCell {
	UILabel *_label;
	UITextField *_textField;
}
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, readonly) UITextField *textField;
@end