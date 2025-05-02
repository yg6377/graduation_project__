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
      'nickname': widget.fromNickname,
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leave a review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => _rating = index + 1.0),
            );
          }),
        ),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: 'Comment',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
        ),
      ],
    );
  }
}