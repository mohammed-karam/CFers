

class UserModel {
  final String country;
  final String lastName;
  final int lastOnlineTimeSeconds;
  final int rating;
  final int friendOfCount;
  final String titlePhoto;
  final String handle;
  final String avatar;
  final String firstName;
  final int contribution;
  final String organization;
  final String rank;
  final int maxRating;
  final int registrationTimeSeconds;
  final String maxRank; 


  UserModel({
    required this.country,
    required this.lastName,
    required this.lastOnlineTimeSeconds,
    required this.rating,
    required this.friendOfCount,
    required this.titlePhoto,
    required this.handle,
    required this.avatar,
    required this.firstName,
    required this.contribution,
    required this.organization,
    required this.rank,
    required this.maxRating,
    required this.registrationTimeSeconds,
    required this.maxRank,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      country: json['country'] as String,
      lastName: json['lastName'] as String,
      lastOnlineTimeSeconds: json['lastOnlineTimeSeconds'] as int,
      rating: json['rating'] as int,  
      friendOfCount: json['friendOfCount'] as int,
      titlePhoto: json['titlePhoto'] as String,
      handle: json['handle'] as String,
      avatar: json['avatar'] as String,
      firstName: json['firstName'] as String,
      contribution: json['contribution'] as int,
      organization: json['organization'] as String? ?? '',
      rank: json['rank'] as String,
      maxRating: json['maxRating'] as int,
      registrationTimeSeconds: json['registrationTimeSeconds'] as int,
      maxRank: json['maxRank'] as String,
    );
  }
}



// {
// "status": "OK",
// "result": [
// {
// "lastName": "Khodyrev",
// "lastOnlineTimeSeconds": 1781856145,
// "rating": 1709,
// "friendOfCount": 97,
// "titlePhoto": "https://userpic.codeforces.org/1592/title/27e43714e4bea090.jpg",
// "handle": "DmitriyH",
// "avatar": "https://userpic.codeforces.org/1592/avatar/7cef566902732053.jpg",
// "firstName": "Dmitriy",
// "contribution": 0,
// "organization": "",
// "rank": "expert",
// "maxRating": 2072,
// "registrationTimeSeconds": 1268570311,
// "maxRank": "candidate master"
// },
// {
// "lastName": "Fefer",
// "country": "Russia",
// "lastOnlineTimeSeconds": 1754027560,
// "city": "Saratov",
// "rating": 2174,
// "friendOfCount": 424,
// "titlePhoto": "https://userpic.codeforces.org/242/title/151ab49dee0779f8.jpg",
// "handle": "Fefer_Ivan",
// "avatar": "https://userpic.codeforces.org/242/avatar/c4e6a102a9e66281.jpg",
// "firstName": "Ivan",
// "contribution": 0,
// "organization": "Booking.com",
// "rank": "master",
// "maxRating": 2476,
// "registrationTimeSeconds": 1264960450,
// "maxRank": "grandmaster"
// }
// ]
// }