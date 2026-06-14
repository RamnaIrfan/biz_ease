# 📄 Product Description Generation – Quick Overview

- **Input fields**: The Add/Edit Product screen collects **product name** and **price** (also category, stock, etc.).
- **Trigger**: User taps the **"Generate with AI"** button next to the description text field.
- **Loading state**: UI sets `_isGeneratingDescription = true` and shows a spinner.
- **Keyword preparation**: The code builds a keyword string:
  ```dart
  final keywords = "${_nameController.text}, $_selectedCategory";
  ```
- **AI call**: It creates an `AIService` instance and calls:
  ```dart
  final description = await aiService.generateProductDescription(
    _nameController.text,
    keywords,
  );
  ```
  The service sends a prompt to Gemini:
  > "Write a compelling product description for \"<name>\". Keywords: <keywords>. Keep it concise, engaging, and suitable for an e‑commerce app."
- **Result handling**:
  - If a non‑null string is returned, it is assigned to the description controller (`_descriptionController.text`).
  - Errors (quota exceeded, network) are caught and shown via a SnackBar.
- **UI update**: The loading flag is cleared (`_isGeneratingDescription = false`) and the newly‑generated description appears in the multi‑line text field, ready for the owner to edit or accept.

**Result**: With a single tap the owner gets a polished, AI‑crafted product description without manual writing.
