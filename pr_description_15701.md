# Fix command mode tab completion for paths with spaces (Issue #15701)

## Problem

When using tab completion in command mode for paths containing spaces, Helix has several issues:

1. After the first tab completion adds single quotes around a path with spaces (e.g., `:cd ~/Some` -> `:cd '~/Some Directory'`), pressing tab again does not show subdirectories or other matching paths.
2. When manually typing after a quoted path (e.g., `:cd 'test me'/jjj`), the tokenizer parses this as two separate arguments, causing an error "expected exactly 1 argument, got 2".

### Steps to Reproduce

1. Type `:change-current-directory ~/Some`
2. Press Tab to complete a directory named "Some Directory"
3. Helix completes to `:change-current-directory '~/Some Directory'`
4. Press Tab again
5. Expected: Show subdirectories of `~/Some Directory` or cycle to other matching directories
6. Actual: No completions are shown

## Root Cause

There were three issues:

1. **In `helix-term/src/commands/typed.rs` (`complete_command_args`)**: The function had a check that prevented completion on ANY terminated token:
   ```rust
   if token.is_terminated {
       return Vec::new();
   }
   ```
   This blocked completion for `TokenKind::Quoted` tokens (single-quoted or backtick-quoted strings), which are used for literal paths including those with spaces.

2. **In `helix-term/src/commands/typed.rs` (`quote_completion`)**: For `TokenKind::Quoted` tokens, the function only escaped inner quotes but used an incorrect range calculation. This caused issues when applying completions to quoted paths.

3. **In `helix-term/src/ui/prompt.rs`**: After applying a tab completion, the completion list was not being recalculated except in a special case. This meant that after the first tab completion (which changed the line by adding quotes), the stale completion list was retained for subsequent tab presses.

## Solution

### Fix 1: Allow completion for terminated quoted tokens
Modified the check in `complete_command_args` to only skip completion for non-quoted terminated tokens:
```rust
if token.is_terminated && !matches!(token.kind, TokenKind::Quoted(_)) {
    return Vec::new();
}
```
This allows completion to proceed for terminated `Quoted` tokens while still preventing completion after the closing delimiter for `Expand` tokens (double quotes).

### Fix 2: Correctly handle quoted token completion
Modified `quote_completion` for `TokenKind::Quoted` to:
- Keep the existing opening quote in the line
- Replace only the content inside the quotes
- Add the closing quote to the span content
- Use the correct range starting from the first character of the content

```rust
TokenKind::Quoted(quote) => {
    let quote_char = quote.char();
    span.content = Cow::Owned(format!(
        "{}{}",
        replace(span.content, quote_char, quote.escape()),
        quote_char
    ));
    ((offset + token.content_start).., span)
}
```

This ensures that for a quoted path like `'test me'`, the completion replaces `test me` (the content) with `test me/subdir'` (content + closing quote), preserving the opening quote and resulting in `'test me/subdir'`.

### Fix 3: Recalculate completions after tab completion
Modified the tab key handler in `Prompt::handle_event` to always call `recalculate_completion` after applying a completion:
```rust
key!(Tab) => {
    self.change_completion_selection(CompletionDirection::Forward);
    self.recalculate_completion(cx.editor);
    (self.callback_fn)(cx, &self.line, PromptEvent::Update)
}
shift!(Tab) => {
    self.change_completion_selection(CompletionDirection::Backward);
    self.recalculate_completion(cx.editor);
    (self.callback_fn)(cx, &self.line, PromptEvent::Update)
}
```
This ensures that the completion list is always up-to-date after a tab completion is applied, which is necessary when the applied completion changes the line (e.g., by adding quotes or appending subdirectories).

### Fix 4: Position cursor before closing quote (UX improvement)
Modified `change_completion_selection` to position the cursor before the closing quote when a completion ends with a quote. This allows the user to continue typing inside the quoted string without manually moving the cursor.

```rust
// If the completion ends with a single or backtick quote, position cursor before it
if let Some(last_char) = item.content.chars().last() {
    if last_char == '\'' || last_char == '`' {
        let pos = self.line.len();
        if pos > 0 {
            self.cursor = pos - 1;
            return;
        }
    }
}
self.move_end();
```

## Testing

After these fixes:
- First Tab on `:cd ~/Some` completes to `:cd '~/Some Directory'`
- Second Tab shows subdirectories of `~/Some Directory` or cycles to other matching directories (e.g., `'~/Some Other Directory'`)
- User can continue typing after tab completion and it stays inside the quotes
- Tab completion works correctly for all path completions

## Files Modified

- `helix-term/src/commands/typed.rs`:
  - Line 4208: Updated the termination check in `complete_command_args`
  - Lines 4307-4317: Fixed `quote_completion` for Quoted tokens
- `helix-term/src/ui/prompt.rs`:
  - Lines 393-403: Position cursor before closing quote after completion
  - Lines 733, 737: Always recalculate completions after tab completion
