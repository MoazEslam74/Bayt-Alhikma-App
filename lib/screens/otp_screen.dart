import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; 

class OTPScreen extends StatefulWidget {
  final String verificationId; 
  final bool isLinking; // المتغير الجديد عشان نحدد نوع العملية

  const OTPScreen({
    Key? key, 
    required this.verificationId, 
    this.isLinking = false, // القيمة الافتراضية إنه بيسجل دخول
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOTP() async {
    setState(() { isLoading = true; });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      if (widget.isLinking) {
        // لو جاي من الـ Sign Up -> هنعمل ربط للحساب الحالي
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
        print("تم ربط رقم الموبايل بالحساب بنجاح!");
      } else {
        // لو جاي من الـ Login -> تسجيل دخول عادي
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
        (route) => false,
      );
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير صحيح، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الرمز')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '123456',
                labelText: 'أدخل الكود المكون من 6 أرقام',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: verifyOTP,
                    child: const Text('تأكيد'),
                  ),
          ],
        ),
      ),
    );
  }
}