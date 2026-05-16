import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // 🔴 Ensure the API Key is correct
  static const String _apiKey = 'AIzaSyCEarXzWjxjyBPu5bni9MC5zx-KkNY87U4'; 

  late final GenerativeModel _model;

  GeminiService() {
    // Use 'gemini-1.5-pro' for best speed and stability
    _model = GenerativeModel(
      model: 'gemini-2.5-pro', 
      apiKey: _apiKey,
    );
  }

  /// 🧠 Generate User Analysis Report
  /// Takes a structured prompt and returns a JSON string for parsing.
  Future<String?> generateUserReport(String dataPrompt) async {
    try {
      const String systemInstruction = """
      [SYSTEM ROLE]
      You are an advanced Data Analyst AI for a university campus app.
      Your goal is to analyze user data (spending, library usage, access logs, events) and generate a "Campus Persona" report.

      [OUTPUT FORMAT]
      You MUST return a valid JSON object. Do not include markdown formatting (like ```json).
      The JSON structure must be:
      {
        "summary": "A warm, encouraging summary of their month (max 30 words).",
        "keywords": ["Keyword1", "Keyword2", "Keyword3"],
        "persona": "A creative title based on behavior (e.g., 'Library Ghost', 'Social Butterfly', 'Coffee Addict').",
        "spendingBreakdown": {
          "Food": 120.50,
          "Transport": 30.00
        },
        "suggestion": "One specific, actionable suggestion for next month."
      }

      [TONE]
      - Youthful, energetic, and encouraging.
      - Use emojis where appropriate in the summary and suggestion.
      """;

      final content = [
        Content.text(systemInstruction),
        Content.text("User Data:\n$dataPrompt"),
      ];

      // Use a separate model instance or config if needed, but reusing _model is fine for now.
      // Ideally, we'd set generationConfig to responseMimeType: 'application/json' if supported,
      // but for now we rely on the prompt.
      final response = await _model.generateContent(content);
      
      String? result = response.text;
      
      // Clean up markdown code blocks if present
      if (result != null) {
        result = result.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      return result;
    } catch (e) {
      print("Gemini Analysis Error: $e");
      return null;
    }
  }

  Future<String?> sendMessage(String userMessage) async {
    try {
      // 📚 Employee Handbook V4.0: Added Events & Tickets Module
      const String appManual = """
      [SYSTEM INSTRUCTION]
      You are 'QRVI Bot', the official AI Support for the 'QR Virtual Identity' app.
      Answer users based strictly on the KNOWLEDGE BASE below. Be concise and professional.

      [KNOWLEDGE BASE]

      === 1. Digital ID (The QR Code) ===
      * **Function**: Virtual credential for Payments, Door Access, and Library.
      * **Privacy**: BLURRED by default. Tap -> Biometric Auth -> Reveal.
      * **Security**: Refreshes every 60s. Screenshots are INVALID.
      * **Offline**: Works offline using cached data.

      === 2. Inbox (Notifications Center) ===
      * **Function**: Real-time history of campus interactions.
      * **Icon Meanings**:
        - 🛍️ **Pink (Bag)**: Payment receipts.
        - 🚪 **Green (Door)**: Door access logs.
        - 📘 **Blue (Book)**: Library borrowing.

      === 3. Profile & Stats ===
      * **Overview**: Identity, Tickets count, Points, and Badges.
      * **Avatar**: Uses Google Photo or auto-generated Dicebear avatar.
      * **Troubleshooting**: If stats error, click 'Retry'.

      === 4. Events & Tickets (New!) ===
      * **Viewing Events**: 
        - Go to 'Events & Tickets' page. 
        - The list updates in **Real-time** (no refresh needed) when new events are added.
      * **Joining**: 
        - Tap 'Book Slot'. System checks capacity instantly. 
        - If successful, the button changes to 'View Ticket'.
      * **Ticket Status & Colors**:
        - 🟢 **Green (ACTIVE)**: Registered successfully, ready to attend.
        - 🔵 **Blue (ATTENDED)**: You have successfully scanned/checked-in at the venue.
        - ⚪ **Grey (CANCELLED)**: Event cancelled or booking cancelled.
      * **How to Check-in (Attendance)**:
        - Open your Ticket -> Show the QR Code to the admin scanner.
        - Once scanned, your screen will **automatically** turn Blue (CHECK-IN COMPLETED).

      === 5. Account & Security ===
      * **Sign Out**: Profile -> Sign Out.
      * **Policy**: Logging in on a new device forces logout on old devices.

      [COMMON QUESTIONS]
      - "Why is my ticket green?" -> It means your booking is active, go to the event!
      - "How do I sign attendance?" -> Open the ticket and show the QR code to the staff.
      - "Can I join if the event is full?" -> No, the 'Book Slot' button will be disabled if capacity is full.

      [RULES]
      - If the user asks unrelated questions, politely decline.
      - Only answer based on the info above.
      """;

      // 🔄 Compose Prompt
      final prompt = """
      $appManual
      
      User Question:
      $userMessage
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text;
    } catch (e) {
      print("Gemini Error: $e");
      return "Sorry, I am having trouble connecting to the server. Please try again later.";
    }
  }
}