import '../models/question_model.dart';

class QuestionData {
  static const List<QuestionModel> physicsQuestions = [
    QuestionModel(
      id: 'physics_001',
      subject: 'Physics',
      chapter: 'Kinematics',
      topic: 'Velocity',
      difficulty: 'Easy',
      question:
      'A particle is moving with a velocity of 20 m/s. What is its velocity after the same motion continues?',
      options: [
        '10 m/s',
        '20 m/s',
        '30 m/s',
        '40 m/s',
      ],
      correctAnswer: 1,
      explanation:
      'The velocity remains 20 m/s when the same motion continues.',
      marks: 4,
    ),

    QuestionModel(
      id: 'physics_002',
      subject: 'Physics',
      chapter: 'Kinematics',
      topic: 'Velocity',
      difficulty: 'Easy',
      question:
      'Which physical quantity is measured in metres per second (m/s)?',
      options: [
        'Acceleration',
        'Force',
        'Velocity',
        'Energy',
      ],
      correctAnswer: 2,
      explanation:
      'Velocity is the rate of change of displacement and is measured in m/s.',
      marks: 4,
    ),

    QuestionModel(
      id: 'physics_003',
      subject: 'Physics',
      chapter: 'Kinematics',
      topic: 'Acceleration',
      difficulty: 'Easy',
      question:
      'What happens to the velocity of an object when its acceleration is zero?',
      options: [
        'It always increases',
        'It remains constant',
        'It becomes zero',
        'It always decreases',
      ],
      correctAnswer: 1,
      explanation:
      'When acceleration is zero, the velocity remains constant.',
      marks: 4,
    ),
  ];
}