const String userApiKey = "097cf44e985ad1c2fd38978a9318c38a2eca58fc";
const String userApiSecret = "4a621bc2aeaffe035bab12d718f1e88b0cea0916";

// Shared API Key for all users (onlinecompiler.io)
const String onlineCompilerApiKey = "4f9845491eb343d37bb2d2ae2a2d3a9e";

// Groq powers the AI Answer Checker. Every student supplies their own key
// from Settings — see AppSettings.groqApiKey — so no shared key ships here.
// This is only the fallback model, also changeable in Settings.
const String kDefaultGroqModel = "qwen/qwen3.8-27b";
const String groqChatCompletionsUrl =
    "https://api.groq.com/openai/v1/chat/completions";

// Number of attempts a student gets before the full solution is revealed
const int kMaxAnswerTrials = 3;