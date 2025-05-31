import 'package:google_generative_ai/google_generative_ai.dart';

class MedAlpacaService {
  final String apiKey;

  late final GenerativeModel _model;

  MedAlpacaService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getChatResponse(String userInput) async {
    try {
      final response = await _model.generateContent([Content.text(userInput)]);
      return response.text ?? "No response from Gemini.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
