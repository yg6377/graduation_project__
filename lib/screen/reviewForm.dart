import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewForm extends StatefulWidget {
  final String toUserId;        // 리뷰 받는 유저 ID (users/{userId}/reviews)
  final String fromUserId;      // 리뷰 작성자 UID
  final String fromNickname;    // 리뷰 작성자 닉네임

  const ReviewForm({
    Key? key,
    required this.toUserId,
    required this.fromUserId,
    required this.fromNickname,
  }) : super(key: key);

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  bool _alreadyReviewed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.toUserId)
        .collection('reviews')
        .where('fromUid', isEqualTo: widget.fromUserId)
        .limit(1)
        .get();

    setState(() {
      _alreadyReviewed = snapshot.docs.isNotEmpty;
      _isLoading = false;
    });
  }

  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (_rating == 0 || comment.isEmpty) return;

    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.toUserId)  // ✅ 리뷰 대상
        .collection('reviews')
        .add({
      'fromUid': widget.fromUserId,
      'nickname': widget.fromNickname,        // 기존 nickname 필드
      'fromNickname': widget.fromNickname,    // 추가된 fromNickname 필드
      'rating': _rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isSubmitting = false;
      _rating = 0;
    });
    _commentController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review submitted!')),
    );

    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF),
      appBar: AppBar(
        title: Text('Write a Review'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _alreadyReviewed
              ? Center(
                  child: Text(
                    'You already rated this user!',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        'assets/images/huanhuan_happy.png',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate your experience',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      icon: Icon(
                                        index < _rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 30,
                                      ),
                                      onPressed: () => setState(() => _rating = index + 1.0),
                                    );
                                  }),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    labelText: 'Write a comment...',
                                    labelStyle: TextStyle(color: Colors.blueGrey[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  maxLines: 4,
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isSubmitting ? null : _submitReview,
                                    child: Text(
                                      _isSubmitting ? 'Submitting...' : 'Submit Review',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}