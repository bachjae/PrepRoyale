const admin = require('firebase-admin');

// Connect to Firestore emulator - MUST be set before initializeApp
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
}
console.log(`Connecting to Firestore emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'sat-act-battle-royale'
});

const db = admin.firestore();

const sampleQuestions = [
  // ==================== SAT MATH QUESTIONS ====================
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Linear Equations',
    difficulty: 1,
    questionText: 'Solve for x: 2x + 6 = 14',
    choices: ['x = 4', 'x = 5', 'x = 3', 'x = 8'],
    correctAnswer: 0,
    explanation: 'Subtract 6 from both sides: 2x = 8. Divide by 2: x = 4.',
    contentHash: 'sat_math_linear_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Linear Equations',
    difficulty: 2,
    questionText: 'If 3(x - 2) = 15, what is the value of x?',
    choices: ['x = 7', 'x = 5', 'x = 9', 'x = 3'],
    correctAnswer: 0,
    explanation: 'Distribute: 3x - 6 = 15. Add 6: 3x = 21. Divide by 3: x = 7.',
    contentHash: 'sat_math_linear_002',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Quadratic Equations',
    difficulty: 3,
    questionText: 'What are the solutions to x² - 5x + 6 = 0?',
    choices: ['x = 2 and x = 3', 'x = 1 and x = 6', 'x = -2 and x = -3', 'x = 2 and x = -3'],
    correctAnswer: 0,
    explanation: 'Factor: (x - 2)(x - 3) = 0. So x = 2 or x = 3.',
    contentHash: 'sat_math_quad_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Percentages',
    difficulty: 2,
    questionText: 'A shirt originally costs $40. It is on sale for 25% off. What is the sale price?',
    choices: ['$30', '$35', '$25', '$32'],
    correctAnswer: 0,
    explanation: '25% of $40 = $10. Sale price = $40 - $10 = $30.',
    contentHash: 'sat_math_percent_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Geometry',
    difficulty: 2,
    questionText: 'What is the area of a rectangle with length 8 and width 5?',
    choices: ['40', '26', '13', '45'],
    correctAnswer: 0,
    explanation: 'Area = length × width = 8 × 5 = 40.',
    contentHash: 'sat_math_geo_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Statistics',
    difficulty: 2,
    questionText: 'Find the mean of: 4, 8, 6, 10, 7',
    choices: ['7', '6', '8', '35'],
    correctAnswer: 0,
    explanation: 'Mean = (4 + 8 + 6 + 10 + 7) / 5 = 35 / 5 = 7.',
    contentHash: 'sat_math_stat_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Ratios',
    difficulty: 2,
    questionText: 'If the ratio of boys to girls is 3:4 and there are 28 students total, how many boys are there?',
    choices: ['12', '16', '14', '21'],
    correctAnswer: 0,
    explanation: '3 + 4 = 7 parts. 28/7 = 4 students per part. Boys = 3 × 4 = 12.',
    contentHash: 'sat_math_ratio_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Exponents',
    difficulty: 2,
    questionText: 'Simplify: 2³ × 2⁴',
    choices: ['128', '64', '32', '256'],
    correctAnswer: 0,
    explanation: 'When multiplying same bases, add exponents: 2^(3+4) = 2^7 = 128.',
    contentHash: 'sat_math_exp_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Functions',
    difficulty: 3,
    questionText: 'If f(x) = 2x + 3, what is f(5)?',
    choices: ['13', '10', '8', '25'],
    correctAnswer: 0,
    explanation: 'f(5) = 2(5) + 3 = 10 + 3 = 13.',
    contentHash: 'sat_math_func_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Math',
    skill: 'Probability',
    difficulty: 2,
    questionText: 'A bag has 3 red and 5 blue marbles. What is the probability of picking a red marble?',
    choices: ['3/8', '5/8', '3/5', '1/2'],
    correctAnswer: 0,
    explanation: 'Probability = favorable outcomes / total outcomes = 3 / (3+5) = 3/8.',
    contentHash: 'sat_math_prob_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== SAT READING QUESTIONS (with passages) ====================
  {
    examType: 'SAT',
    section: 'Reading',
    skill: 'Main Idea',
    difficulty: 2,
    passage: `The Arctic is warming at nearly twice the rate of the rest of the world, and this has profound consequences for polar bears. These magnificent creatures depend on sea ice as a platform for hunting seals, their primary food source. As temperatures rise, the sea ice forms later in the fall and breaks up earlier in the spring, leaving polar bears with a shorter hunting season.

Scientists have observed that polar bears are now spending more time on land, where food is scarce. Some bears have been seen eating bird eggs, berries, and even garbage—a stark departure from their traditional diet. While polar bears are adaptable, these alternative food sources cannot provide the high-fat content they need to survive the harsh Arctic winters.

Conservation efforts are underway, but the ultimate solution lies in addressing climate change itself. Without significant reductions in greenhouse gas emissions, polar bear populations are projected to decline by more than 30% over the next three decades.`,
    questionText: 'What is the main idea of the passage?',
    choices: [
      'Climate change threatens polar bear survival by reducing their hunting opportunities',
      'Polar bears are the largest land predators in the Arctic',
      'Scientists are studying polar bear eating habits',
      'Arctic ice is melting at a slow but steady rate'
    ],
    correctAnswer: 0,
    explanation: 'The passage focuses on how climate change and melting sea ice affect polar bears\' ability to hunt and survive, making this the main idea.',
    contentHash: 'sat_read_main_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Reading',
    skill: 'Vocabulary in Context',
    difficulty: 2,
    passage: `The young pianist\'s virtuosity was evident from her very first note. Her fingers danced across the keys with a precision and grace that belied her mere twelve years of age. The audience sat in stunned silence as she navigated the complex passages of Chopin\'s Ballade No. 1, a piece that challenges even seasoned professionals.

When the final chord faded, the concert hall erupted in thunderous applause. Critics who had come expecting a talented child prodigy left having witnessed something far more rare: a true musical genius in the making. Her technical mastery was matched only by the emotional depth she brought to each phrase, transforming notes on a page into a living, breathing narrative.`,
    questionText: 'In the context of the passage, "virtuosity" most nearly means:',
    choices: [
      'Exceptional technical skill and artistry',
      'Loud and dramatic performance style',
      'Natural stage presence and confidence',
      'Years of dedicated practice'
    ],
    correctAnswer: 0,
    explanation: 'The passage describes the pianist\'s "precision and grace" and "technical mastery," indicating that virtuosity refers to exceptional skill and artistry.',
    contentHash: 'sat_read_vocab_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Reading',
    skill: 'Inference',
    difficulty: 3,
    passage: `In 1928, Alexander Fleming returned to his laboratory after a vacation to find that a mold had contaminated one of his petri dishes containing Staphylococcus bacteria. Rather than discarding the ruined experiment, Fleming noticed something curious: the bacteria near the mold had been destroyed, while bacteria farther away remained healthy.

Fleming identified the mold as Penicillium notatum and named the antibacterial substance it produced "penicillin." However, Fleming lacked the resources and chemical expertise to purify penicillin for medical use. It wasn\'t until 1940 that Howard Florey and Ernst Boris Chain developed methods to mass-produce the drug, just in time to save countless lives during World War II.

Fleming remained humble about his discovery, often noting that "One sometimes finds what one is not looking for." His accidental observation, combined with his scientific curiosity, changed the course of medical history.`,
    questionText: 'Based on the passage, what can be inferred about scientific discovery?',
    choices: [
      'Important discoveries can result from unexpected observations and curiosity',
      'Scientific breakthroughs always require large teams of researchers',
      'Accidents in the laboratory should always be discarded',
      'Fleming was the sole contributor to the development of penicillin'
    ],
    correctAnswer: 0,
    explanation: 'Fleming\'s quote about finding "what one is not looking for" and the description of his "accidental observation" combined with "scientific curiosity" support the inference that discoveries can come from unexpected observations.',
    contentHash: 'sat_read_inf_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Reading',
    skill: 'Evidence-Based Reading',
    difficulty: 3,
    passage: `The debate over nature versus nurture has fascinated scientists for centuries. Are we primarily shaped by our genes or by our environment? Modern research suggests the answer is neither—and both.

Epigenetics, the study of how environmental factors can influence gene expression, has revolutionized our understanding. While our DNA sequence remains fixed, the way our genes are "read" can change based on our experiences. A child raised in a stressful environment, for example, may have certain stress-response genes activated more strongly than a child raised in a calm household—even if both children have identical genetic predispositions.

This interplay between nature and nurture begins before birth. Studies of identical twins raised apart show remarkable similarities in personality and preferences, suggesting a strong genetic component. Yet these same studies reveal significant differences shaped by their distinct upbringings. The emerging consensus is that genes and environment engage in an intricate dance, each influencing and being influenced by the other.`,
    questionText: 'Which statement best describes the relationship between genetics and environment according to the passage?',
    choices: [
      'Genes and environment interact dynamically, with each influencing the other',
      'Genetics completely determines human development',
      'Environment has no effect on genetic expression',
      'Twin studies prove that nurture is more important than nature'
    ],
    correctAnswer: 0,
    explanation: 'The passage explicitly states that "genes and environment engage in an intricate dance, each influencing and being influenced by the other," supporting the dynamic interaction view.',
    contentHash: 'sat_read_evidence_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== SAT WRITING QUESTIONS ====================
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Grammar',
    difficulty: 1,
    questionText: 'Choose the sentence with correct subject-verb agreement:',
    choices: [
      'The group of students is working on their project.',
      'The group of students are working on their project.',
      'The group of students is working on its project.',
      'The group of students be working on their project.'
    ],
    correctAnswer: 0,
    explanation: '"Group" is a collective noun and takes a singular verb "is." While "their" is often acceptable in modern usage for collective nouns referring to individual members.',
    contentHash: 'sat_write_gram_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Punctuation',
    difficulty: 2,
    questionText: 'Which sentence uses punctuation correctly?',
    choices: [
      'After the rain stopped, we went outside to play.',
      'After the rain stopped we went outside to play.',
      'After, the rain stopped we went outside to play.',
      'After the rain stopped; we went outside to play.'
    ],
    correctAnswer: 0,
    explanation: 'A comma is needed after an introductory adverbial clause ("After the rain stopped").',
    contentHash: 'sat_write_punct_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Sentence Structure',
    difficulty: 2,
    questionText: 'Which revision best combines these sentences? "Marie Curie discovered radium. She won two Nobel Prizes."',
    choices: [
      'Marie Curie, who discovered radium, won two Nobel Prizes.',
      'Marie Curie discovered radium, she won two Nobel Prizes.',
      'Marie Curie discovered radium and she won two Nobel Prizes.',
      'Marie Curie discovering radium, won two Nobel Prizes.'
    ],
    correctAnswer: 0,
    explanation: 'The relative clause "who discovered radium" effectively combines the sentences while maintaining proper grammar and flow.',
    contentHash: 'sat_write_sent_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Transitions',
    difficulty: 2,
    questionText: 'Choose the best transition: "Exercise improves physical health. _____, it enhances mental well-being."',
    choices: [
      'Moreover',
      'However',
      'Nevertheless',
      'Instead'
    ],
    correctAnswer: 0,
    explanation: '"Moreover" indicates addition of a related point, which fits since both sentences discuss benefits of exercise.',
    contentHash: 'sat_write_trans_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Concision',
    difficulty: 2,
    questionText: 'Which option is most concise while maintaining the meaning? "In spite of the fact that it was raining, we decided to go hiking."',
    choices: [
      'Although it was raining, we decided to go hiking.',
      'Despite the fact that rain was falling from the sky, we decided to go hiking.',
      'It was raining but in spite of this we decided to go hiking anyway.',
      'We decided to go hiking even though and despite the rain that was falling.'
    ],
    correctAnswer: 0,
    explanation: '"Although" efficiently replaces "In spite of the fact that" while maintaining the same meaning.',
    contentHash: 'sat_write_concise_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Pronoun Agreement',
    difficulty: 2,
    questionText: 'Select the sentence with correct pronoun usage:',
    choices: [
      'Each of the players brought his or her own equipment.',
      'Each of the players brought their own equipments.',
      'Each of the players brought her own equipment.',
      'Each of the players brought his own equipment.'
    ],
    correctAnswer: 0,
    explanation: '"Each" is singular and requires a singular pronoun. "His or her" is the most inclusive and grammatically correct option.',
    contentHash: 'sat_write_pronoun_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Parallel Structure',
    difficulty: 3,
    questionText: 'Which sentence demonstrates correct parallel structure?',
    choices: [
      'She likes swimming, hiking, and cycling.',
      'She likes swimming, to hike, and cycling.',
      'She likes to swim, hiking, and to cycle.',
      'She likes swimming, hikes, and to cycle.'
    ],
    correctAnswer: 0,
    explanation: 'Parallel structure requires consistent grammatical forms. All three activities should be gerunds (swimming, hiking, cycling).',
    contentHash: 'sat_write_parallel_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'SAT',
    section: 'Writing',
    skill: 'Modifier Placement',
    difficulty: 3,
    questionText: 'Which sentence correctly places the modifier? Original: "Running through the park, the sunset was beautiful."',
    choices: [
      'Running through the park, I found the sunset beautiful.',
      'Running through the park, the sunset looked beautiful to see.',
      'The sunset was beautiful, running through the park.',
      'Running through the park, it was a beautiful sunset.'
    ],
    correctAnswer: 0,
    explanation: 'The modifier "Running through the park" must be followed by the person doing the running (I), not the sunset.',
    contentHash: 'sat_write_modifier_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== ACT MATH QUESTIONS ====================
  {
    examType: 'ACT',
    section: 'Math',
    skill: 'Algebra',
    difficulty: 2,
    questionText: 'Simplify: 3x + 2y - x + 4y',
    choices: ['2x + 6y', '4x + 6y', '2x + 2y', '3x + 6y'],
    correctAnswer: 0,
    explanation: 'Combine like terms: (3x - x) + (2y + 4y) = 2x + 6y.',
    contentHash: 'act_math_alg_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Math',
    skill: 'Trigonometry',
    difficulty: 3,
    questionText: 'In a right triangle, if the opposite side is 3 and the hypotenuse is 5, what is sin(θ)?',
    choices: ['3/5', '4/5', '3/4', '5/3'],
    correctAnswer: 0,
    explanation: 'sin(θ) = opposite/hypotenuse = 3/5.',
    contentHash: 'act_math_trig_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Math',
    skill: 'Geometry',
    difficulty: 2,
    questionText: 'A circle has a radius of 7 cm. What is its circumference? (Use π = 22/7)',
    choices: ['44 cm', '22 cm', '154 cm', '14 cm'],
    correctAnswer: 0,
    explanation: 'Circumference = 2πr = 2 × (22/7) × 7 = 44 cm.',
    contentHash: 'act_math_geo_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Math',
    skill: 'Statistics',
    difficulty: 2,
    questionText: 'What is the median of: 3, 7, 9, 2, 5?',
    choices: ['5', '7', '3', '9'],
    correctAnswer: 0,
    explanation: 'First, arrange in order: 2, 3, 5, 7, 9. The median (middle value) is 5.',
    contentHash: 'act_math_stat_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== ACT READING QUESTIONS (with passages) ====================
  {
    examType: 'ACT',
    section: 'Reading',
    skill: 'Inference',
    difficulty: 2,
    passage: `Technology has transformed how we communicate, but this transformation comes with trade-offs. On one hand, we can instantly connect with anyone around the globe. We can maintain relationships across vast distances, share experiences in real-time, and access information that would have taken our grandparents weeks to obtain.

On the other hand, critics argue that our constant connectivity has made us more isolated than ever. We scroll through social media feeds while ignoring the people sitting beside us. We curate perfect online personas while struggling with real-world conversations. Studies show that despite having hundreds of "friends" online, many people report feeling lonelier than previous generations.

Perhaps the answer lies not in abandoning technology but in using it more mindfully. Technology is a tool, and like any tool, its value depends on how we choose to wield it.`,
    questionText: 'Based on the passage, what can be inferred about the author\'s attitude toward technology?',
    choices: [
      'Cautiously balanced, acknowledging both benefits and drawbacks',
      'Completely negative and dismissive',
      'Entirely enthusiastic without reservations',
      'Indifferent and unconcerned'
    ],
    correctAnswer: 0,
    explanation: 'The author presents "trade-offs," discusses both positive aspects ("instantly connect") and negatives ("more isolated"), and suggests "mindful" use, indicating a balanced perspective.',
    contentHash: 'act_read_inf_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Reading',
    skill: 'Main Idea',
    difficulty: 2,
    passage: `The octopus is perhaps the most intelligent invertebrate on Earth. With eight flexible arms, three hearts, and blue blood, it already seems otherworldly. But its mental capabilities are what truly set it apart from other mollusks.

Octopuses can solve complex puzzles, unscrew jars from the inside, and even recognize individual human faces. They have been observed using tools, carrying coconut shells to use as portable shelters. In laboratory settings, they have escaped from secure tanks, navigated mazes, and demonstrated what appears to be play behavior.

What makes octopus intelligence particularly fascinating is that it evolved independently from vertebrate intelligence. While mammals developed centralized brains, octopuses distributed much of their neural processing to their arms—each arm can taste, touch, and even make basic decisions somewhat independently. This raises profound questions about the nature of consciousness and intelligence itself.`,
    questionText: 'What is the main idea of the passage?',
    choices: [
      'Octopuses display remarkable intelligence that evolved differently from vertebrates',
      'Octopuses have eight arms and three hearts',
      'Scientists study octopuses in laboratory settings',
      'Vertebrates are more intelligent than invertebrates'
    ],
    correctAnswer: 0,
    explanation: 'The passage emphasizes octopus intelligence and notes that "it evolved independently from vertebrate intelligence," making this the central point.',
    contentHash: 'act_read_main_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Reading',
    skill: 'Detail',
    difficulty: 2,
    passage: `The Great Pacific Garbage Patch is not, as many imagine, a solid island of plastic that you could walk across. Instead, it is a vast zone where currents have concentrated millions of pieces of plastic debris, most of it broken down into tiny fragments called microplastics.

Located between Hawaii and California, the patch covers an estimated 1.6 million square kilometers—roughly twice the size of Texas. However, if you sailed through it, you might not immediately notice anything unusual. The plastic is dispersed throughout the water column, with much of it floating just below the surface.

The true danger lies in these microplastics entering the food chain. Fish mistake tiny plastic particles for food, and these particles accumulate in their tissues. As larger animals eat smaller ones, the concentration of plastics increases—a process called biomagnification. Eventually, these plastics may end up in the seafood on our dinner plates.`,
    questionText: 'According to the passage, where is the Great Pacific Garbage Patch located?',
    choices: [
      'Between Hawaii and California',
      'Near the coast of Japan',
      'In the Atlantic Ocean',
      'Along the Pacific coast of South America'
    ],
    correctAnswer: 0,
    explanation: 'The passage directly states the patch is "Located between Hawaii and California."',
    contentHash: 'act_read_detail_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== ACT ENGLISH QUESTIONS ====================
  {
    examType: 'ACT',
    section: 'English',
    skill: 'Sentence Structure',
    difficulty: 2,
    questionText: 'Which revision corrects the run-on sentence? "I love pizza it is my favorite food."',
    choices: [
      'I love pizza; it is my favorite food.',
      'I love pizza it, is my favorite food.',
      'I love, pizza it is my favorite food.',
      'I love pizza is my favorite food.'
    ],
    correctAnswer: 0,
    explanation: 'A semicolon correctly joins two related independent clauses.',
    contentHash: 'act_eng_sent_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'English',
    skill: 'Grammar',
    difficulty: 2,
    questionText: 'Select the correct form: "Neither the students nor the teacher _____ ready for the test."',
    choices: [
      'was',
      'were',
      'are',
      'have been'
    ],
    correctAnswer: 0,
    explanation: 'With "neither...nor," the verb agrees with the nearer subject. "Teacher" is singular, so "was" is correct.',
    contentHash: 'act_eng_gram_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'English',
    skill: 'Word Choice',
    difficulty: 2,
    questionText: 'Choose the correct word: "The medicine had a positive _____ on the patient\'s health."',
    choices: [
      'effect',
      'affect',
      'affective',
      'effective'
    ],
    correctAnswer: 0,
    explanation: '"Effect" is a noun meaning result or impact. "Affect" is typically a verb meaning to influence.',
    contentHash: 'act_eng_word_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'English',
    skill: 'Punctuation',
    difficulty: 2,
    questionText: 'Which sentence uses apostrophes correctly?',
    choices: [
      'The dog\'s toys were scattered across the children\'s room.',
      'The dogs toys were scattered across the childrens room.',
      'The dog\'s toys were scattered across the childrens\' room.',
      'The dogs\' toy\'s were scattered across the children\'s room.'
    ],
    correctAnswer: 0,
    explanation: '"Dog\'s" shows possession by one dog, and "children\'s" is the correct possessive form of the irregular plural "children."',
    contentHash: 'act_eng_punct_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'English',
    skill: 'Rhetorical Skills',
    difficulty: 3,
    questionText: 'Which sentence provides the best introduction to a paragraph about the benefits of reading?',
    choices: [
      'Reading offers numerous cognitive and emotional benefits that extend far beyond entertainment.',
      'Some people like to read books.',
      'Libraries contain many books.',
      'Reading is something that humans do.'
    ],
    correctAnswer: 0,
    explanation: 'This sentence clearly introduces the topic (benefits of reading) and previews the content (cognitive and emotional benefits).',
    contentHash: 'act_eng_rhet_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== ACT WRITING QUESTIONS ====================
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Grammar',
    difficulty: 2,
    questionText: 'Choose the sentence with correct subject-verb agreement:',
    choices: [
      'The committee has made its decision.',
      'The committee have made their decision.',
      'The committee have made its decision.',
      'The committee has made their decisions.'
    ],
    correctAnswer: 0,
    explanation: 'In American English, collective nouns like "committee" take singular verbs ("has") and singular pronouns ("its").',
    contentHash: 'act_write_gram_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Punctuation',
    difficulty: 2,
    questionText: 'Which sentence correctly uses a colon?',
    choices: [
      'She needed three things: patience, determination, and courage.',
      'She needed: three things patience, determination, and courage.',
      'She needed three things patience: determination, and courage.',
      'She: needed three things patience, determination, and courage.'
    ],
    correctAnswer: 0,
    explanation: 'A colon introduces a list after a complete sentence. "She needed three things" is complete, so the colon correctly introduces the list.',
    contentHash: 'act_write_punct_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Sentence Structure',
    difficulty: 2,
    questionText: 'Which option correctly fixes the sentence fragment? "Because the weather was terrible."',
    choices: [
      'Because the weather was terrible, we stayed inside.',
      'Because the weather was terrible, inside.',
      'Because. The weather was terrible.',
      'Terrible because the weather was.'
    ],
    correctAnswer: 0,
    explanation: 'A dependent clause like "Because the weather was terrible" needs to be attached to an independent clause to form a complete sentence.',
    contentHash: 'act_write_sent_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Transitions',
    difficulty: 2,
    questionText: 'Choose the best transition: "The experiment failed. _____, the scientists learned valuable lessons."',
    choices: [
      'Nevertheless',
      'Therefore',
      'Similarly',
      'Consequently'
    ],
    correctAnswer: 0,
    explanation: '"Nevertheless" indicates contrast—the scientists learned something positive despite the failure. "Therefore" and "Consequently" suggest cause-effect, which doesn\'t fit.',
    contentHash: 'act_write_trans_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Word Choice',
    difficulty: 2,
    questionText: 'Select the correct word: "The new policy will _____ all employees starting next month."',
    choices: [
      'affect',
      'effect',
      'affective',
      'effecting'
    ],
    correctAnswer: 0,
    explanation: '"Affect" is the verb meaning to influence or impact. "Effect" is typically a noun (though it can be a verb meaning to bring about).',
    contentHash: 'act_write_word_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Concision',
    difficulty: 2,
    questionText: 'Which revision is most concise? "At this point in time, we are currently in the process of reviewing the data."',
    choices: [
      'We are reviewing the data.',
      'At this point, we are currently reviewing the data.',
      'Currently, at this time, we are reviewing the data.',
      'We are in the process of reviewing the data now.'
    ],
    correctAnswer: 0,
    explanation: '"We are reviewing the data" conveys the same meaning without redundant phrases like "at this point in time" and "in the process of."',
    contentHash: 'act_write_concise_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Parallel Structure',
    difficulty: 3,
    questionText: 'Which sentence uses parallel structure correctly?',
    choices: [
      'The job requires writing reports, analyzing data, and presenting findings.',
      'The job requires writing reports, to analyze data, and presenting findings.',
      'The job requires to write reports, analyzing data, and to present findings.',
      'The job requires writing reports, data analysis, and to present findings.'
    ],
    correctAnswer: 0,
    explanation: 'Parallel structure requires consistent grammatical forms. All three items should be gerund phrases: writing, analyzing, presenting.',
    contentHash: 'act_write_parallel_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Writing',
    skill: 'Clarity',
    difficulty: 2,
    questionText: 'Which revision clarifies the ambiguous pronoun? "When Sarah met Lisa, she was nervous."',
    choices: [
      'Sarah was nervous when she met Lisa.',
      'When Sarah met Lisa, she was nervous about it.',
      'When meeting Lisa, she was nervous.',
      'She was nervous when Sarah met Lisa.'
    ],
    correctAnswer: 0,
    explanation: 'Placing "Sarah" as the subject and "she" immediately after clarifies that Sarah was the nervous one.',
    contentHash: 'act_write_clarity_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },

  // ==================== ACT SCIENCE QUESTIONS (with data tables) ====================
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Data Interpretation',
    difficulty: 2,
    passage: `A scientist studied the effect of temperature on enzyme activity. The following data was collected:

EXPERIMENTAL DATA:
Temperature (°C) | Enzyme Activity (units/min)
      10         |          15
      20         |          32
      30         |          58
      40         |          72
      50         |          45
      60         |          12

The experiment used a constant enzyme concentration and pH level of 7.0. Activity was measured by the amount of product formed per minute.`,
    questionText: 'Based on the data, at what temperature is enzyme activity highest?',
    choices: [
      '40°C',
      '50°C',
      '30°C',
      '60°C'
    ],
    correctAnswer: 0,
    explanation: 'According to the table, enzyme activity is 72 units/min at 40°C, which is the highest value in the data set.',
    contentHash: 'act_sci_data_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Data Interpretation',
    difficulty: 2,
    passage: `A study examined plant growth under different light conditions over 4 weeks:

PLANT HEIGHT DATA (cm):
Week | Full Sun | Partial Shade | Full Shade
  1  |    5     |      4        |     3
  2  |   12     |      9        |     5
  3  |   22     |     15        |     7
  4  |   35     |     22        |     8

All plants received equal water and nutrients. Height was measured from soil level to the highest leaf.`,
    questionText: 'What is the difference in height between Full Sun and Full Shade plants at Week 4?',
    choices: [
      '27 cm',
      '35 cm',
      '8 cm',
      '13 cm'
    ],
    correctAnswer: 0,
    explanation: 'Full Sun at Week 4: 35 cm. Full Shade at Week 4: 8 cm. Difference: 35 - 8 = 27 cm.',
    contentHash: 'act_sci_data_002',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Scientific Method',
    difficulty: 2,
    questionText: 'In a controlled experiment, what is the purpose of keeping all variables constant except the independent variable?',
    choices: [
      'To ensure that any observed changes are due to the independent variable',
      'To make the experiment easier to conduct',
      'To reduce the cost of the experiment',
      'To increase the number of trials'
    ],
    correctAnswer: 0,
    explanation: 'Controlling variables isolates the effect of the independent variable, allowing researchers to establish cause-and-effect relationships.',
    contentHash: 'act_sci_method_001_v2',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Data Interpretation',
    difficulty: 3,
    passage: `Researchers measured the concentration of dissolved oxygen in a lake at different depths:

DISSOLVED OXYGEN DATA:
Depth (m) | Oxygen (mg/L) | Temperature (°C)
    0     |     9.2       |      22
    5     |     8.8       |      20
   10     |     7.5       |      15
   15     |     5.2       |      10
   20     |     3.1       |       6
   25     |     1.8       |       5

Measurements were taken on a summer afternoon.`,
    questionText: 'Based on the data, what is the relationship between depth and dissolved oxygen?',
    choices: [
      'As depth increases, dissolved oxygen decreases',
      'As depth increases, dissolved oxygen increases',
      'Depth and dissolved oxygen are not related',
      'Dissolved oxygen remains constant at all depths'
    ],
    correctAnswer: 0,
    explanation: 'The data shows oxygen levels dropping from 9.2 mg/L at the surface to 1.8 mg/L at 25m depth, demonstrating an inverse relationship.',
    contentHash: 'act_sci_data_003',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Experimental Design',
    difficulty: 3,
    passage: `Two scientists conducted experiments on plant growth:

Scientist 1: Grew 30 tomato plants in identical soil, giving 10 plants 100mL of water daily, 10 plants 200mL, and 10 plants 300mL. All plants received the same amount of light. After 6 weeks, she measured plant height.

Scientist 2: Grew 30 tomato plants, giving each plant 200mL of water daily. Ten plants received 6 hours of light, 10 received 12 hours, and 10 received 18 hours. After 6 weeks, he measured plant height.`,
    questionText: 'What variable is Scientist 1 testing?',
    choices: [
      'The effect of water amount on plant growth',
      'The effect of light duration on plant growth',
      'The effect of soil type on plant growth',
      'The effect of temperature on plant growth'
    ],
    correctAnswer: 0,
    explanation: 'Scientist 1 varied only the amount of water (100mL, 200mL, 300mL) while keeping other factors constant, so water amount is the independent variable being tested.',
    contentHash: 'act_sci_exp_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    examType: 'ACT',
    section: 'Science',
    skill: 'Analysis',
    difficulty: 2,
    passage: `A chemistry student recorded the following data for a neutralization reaction:

REACTION DATA:
Volume of Acid (mL) | pH Before | pH After Adding Base
        10          |    2.1    |        5.8
        20          |    1.8    |        6.2
        30          |    1.5    |        6.8
        40          |    1.3    |        7.0
        50          |    1.1    |        7.4

Equal volumes of base were added in each trial.`,
    questionText: 'At what volume of acid does the pH after adding base reach neutral (pH 7)?',
    choices: [
      '40 mL',
      '30 mL',
      '50 mL',
      '20 mL'
    ],
    correctAnswer: 0,
    explanation: 'The table shows pH 7.0 (neutral) is achieved when 40 mL of acid is used.',
    contentHash: 'act_sci_analysis_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function seedQuestions() {
  console.log('Starting to seed questions...');
  console.log(`Total questions to seed: ${sampleQuestions.length}`);

  // First, clear existing questions to avoid duplicates
  const existingQuestions = await db.collection('questions').get();
  if (!existingQuestions.empty) {
    console.log(`Deleting ${existingQuestions.size} existing questions...`);
    const deletePromises = existingQuestions.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
  }

  const batch = db.batch();

  for (const question of sampleQuestions) {
    const docRef = db.collection('questions').doc();
    batch.set(docRef, question);
  }

  await batch.commit();

  // Count by section
  const counts = {};
  for (const q of sampleQuestions) {
    const key = `${q.examType} ${q.section}`;
    counts[key] = (counts[key] || 0) + 1;
  }

  console.log('\nQuestions seeded by section:');
  for (const [key, count] of Object.entries(counts).sort()) {
    console.log(`  ${key}: ${count}`);
  }

  console.log(`\nSuccessfully seeded ${sampleQuestions.length} questions!`);
  process.exit(0);
}

seedQuestions().catch(err => {
  console.error('Error seeding questions:', err);
  process.exit(1);
});
