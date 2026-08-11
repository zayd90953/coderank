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

  static const List<QuestionModel> chemistryQuestions = [
    QuestionModel(
      id: 'chemistry_001',
      subject: 'Chemistry',
      chapter: 'Some Basic Concepts of Chemistry',
      topic: 'Mole Concept',
      difficulty: 'Easy',
      question: 'What is the SI unit of amount of substance?',
      options: [
        'Gram',
        'Mole',
        'Kilogram',
        'Litre',
      ],
      correctAnswer: 1,
      explanation:
      'The mole (mol) is the SI base unit used to measure the amount of substance.',
      marks: 4,
    ),
    QuestionModel(
      id: 'chemistry_002',
      subject: 'Chemistry',
      chapter: 'Structure of Atom',
      topic: 'Subatomic Particles',
      difficulty: 'Easy',
      question: 'Which subatomic particle carries a negative charge?',
      options: [
        'Proton',
        'Neutron',
        'Electron',
        'Nucleus',
      ],
      correctAnswer: 2,
      explanation:
      'An electron carries a negative electric charge.',
      marks: 4,
    ),
    QuestionModel(
      id: 'chemistry_003',
      subject: 'Chemistry',
      chapter: 'Structure of Atom',
      topic: 'Atomic Structure',
      difficulty: 'Easy',
      question: 'Which particle has approximately the same mass as a proton?',
      options: [
        'Electron',
        'Neutron',
        'Photon',
        'Positron',
      ],
      correctAnswer: 1,
      explanation:
      'A neutron has approximately the same mass as a proton.',
      marks: 4,
    ),
  ];

  static const List<QuestionModel> biologyQuestions = [
    QuestionModel(
      id: 'biology_001',
      subject: 'Biology',
      chapter: 'Cell: The Unit of Life',
      topic: 'Cell Biology',
      difficulty: 'Easy',
      question:
      'Which organelle is known as the powerhouse of the cell?',
      options: [
        'Nucleus',
        'Ribosome',
        'Mitochondria',
        'Golgi apparatus',
      ],
      correctAnswer: 2,
      explanation:
      'Mitochondria produce ATP through cellular respiration and are commonly called the powerhouse of the cell.',
      marks: 4,
    ),
    QuestionModel(
      id: 'biology_002',
      subject: 'Biology',
      chapter: 'Cell: The Unit of Life',
      topic: 'Cell Structure',
      difficulty: 'Easy',
      question:
      'Which structure controls most activities of a eukaryotic cell?',
      options: [
        'Cell wall',
        'Nucleus',
        'Vacuole',
        'Cytoplasm',
      ],
      correctAnswer: 1,
      explanation:
      'The nucleus contains the genetic material and controls many activities of a eukaryotic cell.',
      marks: 4,
    ),
    QuestionModel(
      id: 'biology_003',
      subject: 'Biology',
      chapter: 'Biomolecules',
      topic: 'Proteins',
      difficulty: 'Easy',
      question: 'Proteins are primarily made up of which building blocks?',
      options: [
        'Fatty acids',
        'Monosaccharides',
        'Amino acids',
        'Nucleotides',
      ],
      correctAnswer: 2,
      explanation:
      'Proteins are polymers made up of amino acids linked together by peptide bonds.',
      marks: 4,
    ),
  ];
}