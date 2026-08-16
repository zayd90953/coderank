import '../models/question_model.dart';

class QuestionData {
  static const List<QuestionModel> physicsQuestions = [
    QuestionModel(
      id: 'physics_001',
      subject: 'Physics',
      branch: 'NEET',
      chapter: 'Kinematics',
      coreConcept: 'Velocity',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'physics_002',
      subject: 'Physics',
      branch: 'NEET',
      chapter: 'Kinematics',
      coreConcept: 'Velocity',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'physics_003',
      subject: 'Physics',
      branch: 'NEET',
      chapter: 'Kinematics',
      coreConcept: 'Acceleration',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
  ];

  static const List<QuestionModel> chemistryQuestions = [
    QuestionModel(
      id: 'chemistry_001',
      subject: 'Chemistry',
      branch: 'NEET',
      chapter: 'Some Basic Concepts of Chemistry',
      coreConcept: 'Mole Concept',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'chemistry_002',
      subject: 'Chemistry',
      branch: 'NEET',
      chapter: 'Structure of Atom',
      coreConcept: 'Subatomic Particles',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'chemistry_003',
      subject: 'Chemistry',
      branch: 'NEET',
      chapter: 'Structure of Atom',
      coreConcept: 'Atomic Structure',
      questionType: 'Concept check',
      difficulty: 'Easy',
      question:
      'Which particle has approximately the same mass as a proton?',
      options: [
        'Electron',
        'Neutron',
        'Photon',
        'Positron',
      ],
      correctAnswer: 1,
      explanation:
      'A neutron has approximately the same mass as a proton.',
      sourcePattern: 'Test question',
    ),
  ];

  static const List<QuestionModel> biologyQuestions = [
    QuestionModel(
      id: 'biology_001',
      subject: 'Biology',
      branch: 'NEET',
      chapter: 'Cell: The Unit of Life',
      coreConcept: 'Cell Biology',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'biology_002',
      subject: 'Biology',
      branch: 'NEET',
      chapter: 'Cell: The Unit of Life',
      coreConcept: 'Cell Structure',
      questionType: 'Concept check',
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
      sourcePattern: 'Test question',
    ),
    QuestionModel(
      id: 'biology_003',
      subject: 'Biology',
      branch: 'NEET',
      chapter: 'Biomolecules',
      coreConcept: 'Proteins',
      questionType: 'Concept check',
      difficulty: 'Easy',
      question:
      'Proteins are primarily made up of which building blocks?',
      options: [
        'Fatty acids',
        'Monosaccharides',
        'Amino acids',
        'Nucleotides',
      ],
      correctAnswer: 2,
      explanation:
      'Proteins are polymers made up of amino acids linked together by peptide bonds.',
      sourcePattern: 'Test question',
    ),
  ];
}