import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future main(final context) async {
  final body = jsonDecode(context.req.body);

  // ✅ Read Paystack key from Appwrite Environment Variables
  final String secretKey = Platform.environment['PAYSTACK_SECRET_KEY'] ?? "";

  if (secretKey.isEmpty) {
    print("❌ PAYSTACK_SECRET_KEY not set in environment!");
    return context.res.json({
      "verified": false,
      "error": "Server misconfiguration: PAYSTACK_SECRET_KEY is missing."
    });
  }

  print("✅ PAYSTACK_SECRET_KEY loaded.");

  // 1️⃣ VERIFY TRANSACTION
  if (body["action"] == "verify") {
    final String reference = body["reference"]?.toString() ?? "";
    print("🔍 Checking Paystack Reference: $reference");

    if (reference.isEmpty) {
      return context.res.json(
          {"verified": false, "error": "No transaction reference provided."});
    }

    try {
      final res = await http.get(
        Uri.parse("https://api.paystack.co/transaction/verify/$reference"),
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      print("📩 Paystack API Response: $data");

      final bool status = data["data"]?["status"] == "success";

      return context.res.json({
        "verified": status,
        "reference": reference,
        "gateway_response": data["data"]?["gateway_response"],
        "raw": data,
      });
    } catch (e) {
      print("❌ ERROR verifying Paystack transaction: $e");

      return context.res.json({
        "verified": false,
        "error": "Paystack verification failed",
        "details": e.toString(),
      });
    }
  }

  // ❌ Invalid request type
  return context.res.json({
    "error": "Invalid action provided",
    "allowed_actions": ["verify"]
  });
}
