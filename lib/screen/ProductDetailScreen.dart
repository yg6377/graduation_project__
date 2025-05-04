import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project_1/screen/product_comments.dart';
import 'package:graduation_project_1/screen/chatroom_screen.dart';
import 'package:graduation_project_1/screen/edit_product_screen.dart';
import 'package:graduation_project_1/screen/sellerProfileScreen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String timestamp;
  final String sellerEmail;
  final String sellerUid;
  final String chatRoomId;
  final String userName;
  final String productTitle;
  final String productImageUrl;
  final String productPrice;
  final List<String>? imageUrls;
  final Map<String, dynamic> region;

  const ProductDetailScreen({
    required this.productId,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    required this.sellerEmail,
    required this.sellerUid,
    required this.chatRoomId,
    required this.userName,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice,
    required this.region,
    this.imageUrls,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isLiked = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchLikeStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLiked = false;
      });
      return;
    }
    final likeDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('likes')
        .doc(user.uid)
        .get();
    setState(() {
      isLiked = likeDoc.exists && (likeDoc.data()?['liked'] == true);
    });
  }

  Future<void> _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need to Login')),
      );
      return;
    }

    final productDoc = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId);
    final likeRef = productDoc
        .collection('likes')
        .doc(user.uid);
    final likedProductRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('likedProducts')
        .doc(widget.productId); // ✅ productId used as doc ID

    if (!isLiked) {
      await likedProductRef.set({
        'liked': true,
        'productId': widget.productId,
      });
      await likeRef.set({
        'liked': true,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await productDoc.update({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
      });
    } else {
      await likeRef.delete();
      await likedProductRef.delete();
      await productDoc.update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Text(
            '⚠️ Invalid product. No product ID provided.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.sellerUid;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image section with Stack, back button, and more icon
            Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 340,
                  child: Builder(
                    builder: (_) {
                      if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: widget.imageUrls!.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imageUrl = widget.imageUrls![index];
                            return Image.network(imageUrl, fit: BoxFit.cover);
                          },
                        );
                      } else if (widget.imageUrl.isNotEmpty && widget.imageUrl.startsWith('http')) {
                        return Image.network(widget.imageUrl, fit: BoxFit.cover);
                      } else {
                        return Image.asset('assets/images/huanhuan_no_image.png', fit: BoxFit.cover);
                      }
                    },
                  ),
                ),
                // Page indicator
                if (widget.imageUrls != null && widget.imageUrls!.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.imageUrls!.length, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? Colors.white : Colors.white54,
                          ),
                        );
                      }),
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                if (isOwner)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) async {
                          if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditScreen(
                                productId: widget.productId,
                                title: widget.title,
                                price: widget.price,
                                description: widget.description,
                                imageUrl: widget.imageUrls?.isNotEmpty == true ? widget.imageUrls!.first : '',
                              ),
                            ),
                          );
                          } else if (value == 'delete') {
                            bool confirmed = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Comfirm Delete'),
                                content: Text('Are you sure delete your post?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('delete')),
                                ],
                              ),
                            );
                            if (confirmed) {
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(widget.productId)
                                  .delete();
                              Navigator.pop(context);
                            }
                          } else if (value == 'report') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Thank you! Your report has been received!')),
                            );
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(value: 'edit', child: Text('edit')),
                            PopupMenuItem(value: 'delete', child: Text('delete')),
                          ];
                        },
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  // Seller info
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(widget.sellerUid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading uploader info...', style: TextStyle(fontSize: 14, color: Colors.grey));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('Uploader: Unknown', style: TextStyle(fontSize: 14, color: Colors.grey));
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final uidInUserDoc = data['userId'];
                      if (uidInUserDoc != widget.sellerUid) {
                        return Text('⚠️ 판매자 정보가 상품과 일치하지 않습니다.', style: TextStyle(fontSize: 14, color: Colors.red));
                      }
                      final nickname = data['nickname'] ?? 'Unknown';
                      final regionData = data['region'] is Map<String, dynamic> ? data['region'] as Map<String, dynamic> : {};
                      final city = regionData['city'] ?? '';
                      final district = regionData['district'] ?? '';
                      final profileImage = data['profileImageUrl'];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(sellerUid: widget.sellerUid),
                                ),
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: (profileImage != null && profileImage.toString().isNotEmpty)
                                      ? NetworkImage(profileImage)
                                      : AssetImage('assets/images/default_profile.png') as ImageProvider,
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nickname,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.place, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          '$city, $district',
                                          style: TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Divider(color: Colors.grey.shade400),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  // Sale status badge, condition badge, and title
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return SizedBox.shrink();
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final saleStatus = data['saleStatus'] ?? 'selling';
                      final condition = data['condition'] ?? '';
                      Widget? badge;
                      if (saleStatus == 'reserved') {
                        badge = Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFDFF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Reserved',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        );
                      } else if (saleStatus == 'soldout') {
                        badge = Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Sold Out',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badge != null) ...[
                            badge,
                            SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              if (condition.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.only(right: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getConditionColor(condition),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    condition,
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: saleStatus == 'reserved'
                                        ? Colors.black
                                        : saleStatus == 'soldout'
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 9),
                  // Price
                  Text(
                    '${widget.price} NTD',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),

                  SizedBox(height: 3),
                  Text(
                    'Uploaded by: ${widget.timestamp}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  // Description
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            // Left: 좋아요 버튼 + 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                  color: isLiked ? Colors.red : null,
                  onPressed: _toggleLike,
                ),
                SizedBox(width: 5), // 아이콘과 구분선 사이 여백
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.grey,
                ),
                SizedBox(width: 8), // 구분선과 가격 사이 여백
                Text(
                  '${widget.price} NTD',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Spacer(),
            // Right: 댓글 버튼 + Go Chat 버튼 (with right padding and increased spacing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.mode_comment_outlined, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCommentsScreen(
                            productId: widget.productId,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Need to Login')),
                        );
                        return;
                      }

                      final myUid    = currentUser.uid;
                      final sellerUid = widget.sellerUid;
                      if (myUid == sellerUid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You can’t send a message to yourself.')),
                        );
                        return;
                      }

                      // 1) 채팅방 아이디 생성
                      List<String> uids = [myUid, sellerUid]..sort();
                      final chatRoomId = '${uids.join('_')}_${widget.productId}';
                      final chatRef    = FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(chatRoomId);

                      // 2) 채팅방이 없으면, 상품 정보도 같이 읽어서 만든다
                      final chatSnapshot = await chatRef.get();
                      if (chatSnapshot.exists) {
                        final existingData = chatSnapshot.data() as Map<String, dynamic>;
                        final leavers = List<String>.from(existingData['leavers'] ?? []);
                        if (leavers.contains(myUid)) {
                          // Remove current user from leavers list to rejoin chat
                          await chatRef.update({
                            'leavers': FieldValue.arrayRemove([myUid])
                          });
                        }
                      } else {
                        // create new chat room
                        final prodSnap = await FirebaseFirestore.instance
                            .collection('products')
                            .doc(widget.productId)
                            .get();
                        if (!prodSnap.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('상품 정보를 불러올 수 없습니다.')),
                          );
                          return;
                        }
                        final prodData = prodSnap.data()! as Map<String, dynamic>;

                        await chatRef.set({
                          'participants'     : uids,
                          'lastMessage'      : '',
                          'lastTime'         : FieldValue.serverTimestamp(),
                          'location'         : '',
                          'profileImageUrl'  : '',
                          'productId'        : widget.productId,
                          'productTitle'     : prodData['title'] ?? '',
                          'productImageUrl'  : prodData['imageUrl'] ?? '',
                          'productPrice'     : prodData['price'].toString(),
                          'saleStatus'       : prodData['saleStatus'] ?? 'selling',
                          'leavers'          : [], // initialize
                          'productName'      : prodData['productName'] ?? 'Unknown Product',

                        });
                      }

                      // Read product's saleStatus for passing to ChatRoomScreen
                      final prodSnap = await FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.productId)
                          .get();
                      final prodData = prodSnap.data() as Map<String, dynamic>? ?? {};
                      final saleStatus = prodData['saleStatus'] ?? 'selling';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            chatRoomId: chatRoomId,
                            userName:   widget.userName,
                            saleStatus: saleStatus,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Go Chat"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Color _getConditionColor(String condition) {
  switch (condition) {
    case 'S':
      return Colors.green;
    case 'A':
      return Colors.blue;
    case 'B':
      return Colors.orange;
    case 'C':
      return Colors.deepOrange;
    case 'D':
      return Colors.red;
    default:
      return Colors.grey;
  }
}