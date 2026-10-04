class VerificationQuestion {
  const VerificationQuestion({required this.question, required this.options});
  final String question;
  final List<String> options;
}

class GeneratedVerificationQuiz {
  const GeneratedVerificationQuiz({required this.id, required this.topic, required this.questions});
  final String id;
  final String topic;
  final List<VerificationQuestion> questions;
}

class VerificationResult {
  const VerificationResult({required this.passed, required this.score});
  final bool passed;
  final int score;
}

/// Local, predefined quiz bank. No API key, network, or AI service is used.
class CourseVerificationService {
  final Map<String, List<int>> _answerKeys = {};

  Future<GeneratedVerificationQuiz> generate({
    required String title,
    required String category,
    required String courseId,
  }) async {
    final topic = _topicFromTitle(title, category);
    if (topic == null) {
      throw CourseVerificationFailure(
        'Add a supported $category topic to the course title. ${_supportedTopics(category)}',
      );
    }
    final bank = _developmentBank[topic] ?? _nonDevelopmentBank[topic]!;
    final quizId = '${DateTime.now().microsecondsSinceEpoch}-$courseId';
    _answerKeys[quizId] = bank.map((question) => question.correctIndex).toList();
    return GeneratedVerificationQuiz(
      id: quizId,
      topic: topic,
      questions: bank.map((question) => VerificationQuestion(question: question.question, options: question.options)).toList(),
    );
  }

  String? _topicFromTitle(String title, String category) {
    final lower = title.toLowerCase();
    final keywords = _categoryKeywords[category] ?? const <String, List<String>>{};
    for (final entry in keywords.entries) {
      if (entry.value.any(lower.contains)) return entry.key;
    }
    return null;
  }

  String _supportedTopics(String category) =>
      'Supported topics: ${(_categoryKeywords[category]?.keys ?? const <String>[]).join(', ')}.';

  Future<VerificationResult> submit({required String quizId, required List<int> answers}) async {
    final key = _answerKeys.remove(quizId);
    if (key == null || answers.length != key.length) {
      throw const CourseVerificationFailure('This quiz is no longer available. Please generate a new quiz.');
    }
    final score = List.generate(key.length, (index) => answers[index] == key[index] ? 1 : 0)
        .reduce((total, point) => total + point);
    return VerificationResult(passed: score >= 4, score: score);
  }
}

class _BankQuestion {
  const _BankQuestion(this.question, this.options, this.correctIndex);
  final String question;
  final List<String> options;
  final int correctIndex;
}

const _developmentKeywords = <String, List<String>>{
  'JavaScript': ['javascript', 'js ' , 'js:', ' js', 'ecmascript'],
  'C#': ['c#', 'csharp', 'c sharp'],
  'Python': ['python'],
  'Java': ['java'],
  'SQL': ['sql', 'database'],
  'Flutter': ['flutter'],
  'Dart': ['dart'],
  'HTML': ['html'],
  'CSS': ['css'],
  'React': ['react'],
};

const _categoryKeywords = <String, Map<String, List<String>>>{
  'Development': _developmentKeywords,
  'Design & UI/UX': _designKeywords,
  'Marketing': _marketingKeywords,
  'Business': _businessKeywords,
  'Other': _otherKeywords,
};

const _designKeywords = <String, List<String>>{
  'UI Design': ['ui design', 'user interface'], 'UX Research': ['ux research', 'user research'],
  'Figma': ['figma'], 'Adobe XD': ['adobe xd'], 'Wireframing': ['wireframe'],
  'Prototyping': ['prototype'], 'Typography': ['typography', 'fonts'], 'Color Theory': ['color theory', 'colour theory'],
  'Design Systems': ['design system'], 'Accessibility': ['accessibility', 'accessible design'],
};
const _marketingKeywords = <String, List<String>>{
  'SEO': ['seo', 'search engine optimization'], 'Social Media': ['social media'], 'Content Marketing': ['content marketing'],
  'Email Marketing': ['email marketing'], 'Digital Marketing': ['digital marketing'], 'Google Ads': ['google ads', 'ppc'],
  'Branding': ['branding', 'brand strategy'], 'Marketing Analytics': ['marketing analytics'],
  'Influencer Marketing': ['influencer'], 'Copywriting': ['copywriting'],
};
const _businessKeywords = <String, List<String>>{
  'Project Management': ['project management'], 'Business Strategy': ['business strategy', 'strategy'],
  'Human Resources': ['human resources', 'hr '], 'Entrepreneurship': ['entrepreneurship', 'startup'],
  'Management': ['management'], 'Leadership': ['leadership'], 'Finance': ['finance'], 'Accounting': ['accounting'],
  'Sales': ['sales'], 'Operations': ['operations'],
};
const _otherKeywords = <String, List<String>>{
  'Communication': ['communication'], 'Public Speaking': ['public speaking'], 'Career Skills': ['career'],
  'Study Skills': ['study skills', 'study'], 'Productivity': ['productivity'],
};

const _developmentBank = <String, List<_BankQuestion>>{
  'Python': [
    _BankQuestion('What defines code blocks in Python?', ['Indentation', 'Curly brackets', 'Semicolons', 'HTML tags'], 0),
    _BankQuestion('Which keyword defines a function?', ['def', 'function', 'func', 'define'], 0),
    _BankQuestion('Which type is an ordered collection?', ['list', 'int', 'bool', 'float'], 0),
    _BankQuestion('What does print() do?', ['Displays output', 'Deletes a variable', 'Imports a module', 'Creates a class'], 0),
    _BankQuestion('Which symbol starts a comment?', ['#', '//', '<!--', '/*'], 0),
  ],
  'Java': [
    _BankQuestion('Java source code runs on which virtual machine?', ['JVM', 'DOM', 'CSS', 'SQL'], 0),
    _BankQuestion('Which keyword creates an object?', ['new', 'make', 'create', 'object'], 0),
    _BankQuestion('Which method is the usual Java program entry point?', ['main', 'start', 'run', 'init'], 0),
    _BankQuestion('Which type stores whole numbers?', ['int', 'String', 'boolean', 'double only'], 0),
    _BankQuestion('Which keyword is used for inheritance?', ['extends', 'inherits', 'using', 'include'], 0),
  ],
  'JavaScript': [
    _BankQuestion('Where can JavaScript run?', ['Browser and server', 'Only a database', 'Only a compiler', 'Only CSS files'], 0),
    _BankQuestion('Which keyword can declare a block-scoped variable?', ['let', 'select', 'style', 'print'], 0),
    _BankQuestion('What does === compare?', ['Value and type', 'Only variable names', 'Only strings', 'Only arrays'], 0),
    _BankQuestion('Which method writes to the browser console?', ['console.log()', 'print()', 'echo()', 'writeLine()'], 0),
    _BankQuestion('Which is a JavaScript array?', ['[1, 2, 3]', '(1, 2, 3)', '{1, 2, 3}', '<1, 2, 3>'], 0),
  ],
  'C#': [
    _BankQuestion('C# is commonly used with which platform?', ['.NET', 'JVM only', 'PHP only', 'CSS only'], 0),
    _BankQuestion('Which keyword defines a class?', ['class', 'object', 'struct only', 'define'], 0),
    _BankQuestion('Which method is a usual console entry point?', ['Main', 'Start', 'Launch', 'Build'], 0),
    _BankQuestion('Which type stores true or false?', ['bool', 'string', 'int', 'char'], 0),
    _BankQuestion('Which keyword creates an instance?', ['new', 'make', 'create', 'instance'], 0),
  ],
  'SQL': [
    _BankQuestion('Which SQL command reads data?', ['SELECT', 'DELETE', 'DROP', 'UPDATE'], 0),
    _BankQuestion('Which clause filters rows?', ['WHERE', 'ORDER', 'CREATE', 'INSERT'], 0),
    _BankQuestion('Which command adds a new row?', ['INSERT', 'SELECT', 'ALTER', 'DROP'], 0),
    _BankQuestion('What uniquely identifies a table row?', ['Primary key', 'Comment', 'View', 'Query'], 0),
    _BankQuestion('Which command changes existing rows?', ['UPDATE', 'CREATE', 'SELECT', 'GRANT'], 0),
  ],
  'Flutter': [
    _BankQuestion('Flutter applications are built mainly with?', ['Widgets', 'SQL tables', 'HTML only', 'Java bytecode'], 0),
    _BankQuestion('Which widget is commonly used for a page layout?', ['Scaffold', 'SELECT', 'Padding only', 'TextStyle'], 0),
    _BankQuestion('Flutter uses which language?', ['Dart', 'Python', 'SQL', 'C only'], 0),
    _BankQuestion('What does Hot Reload help with?', ['Quick UI updates during development', 'Deleting data', 'Publishing an app', 'Creating a database'], 0),
    _BankQuestion('Which widget displays text?', ['Text', 'Image', 'Column', 'Container only'], 0),
  ],
  'Dart': [
    _BankQuestion('Dart is the primary language of?', ['Flutter', 'React only', 'SQL Server', 'HTML'], 0),
    _BankQuestion('Which keyword declares an immutable variable?', ['final', 'var', 'change', 'set'], 0),
    _BankQuestion('Which keyword defines a function return type?', ['A type before the name', 'SELECT', 'class only', 'HTML'], 0),
    _BankQuestion('Which collection uses key-value pairs?', ['Map', 'List', 'String', 'int'], 0),
    _BankQuestion('Which keyword supports asynchronous waiting?', ['await', 'stop', 'break', 'catch only'], 0),
  ],
  'HTML': [
    _BankQuestion('HTML is used to?', ['Structure web content', 'Style every element', 'Query a database', 'Compile Java'], 0),
    _BankQuestion('Which tag creates a link?', ['<a>', '<p>', '<img>', '<div>'], 0),
    _BankQuestion('Which tag displays an image?', ['<img>', '<a>', '<ul>', '<table>'], 0),
    _BankQuestion('Which tag is the largest heading by default?', ['<h1>', '<h6>', '<p>', '<head>'], 0),
    _BankQuestion('What is an HTML attribute?', ['Extra information on an element', 'A database row', 'A CSS file', 'A Java method'], 0),
  ],
  'CSS': [
    _BankQuestion('CSS is used to?', ['Style web content', 'Store records', 'Run SQL', 'Build Android only'], 0),
    _BankQuestion('Which property changes text color?', ['color', 'font-weight only', 'margin', 'display'], 0),
    _BankQuestion('Which selector targets a class?', ['.className', '#className', 'className()', '<className>'], 0),
    _BankQuestion('Which property adds outside spacing?', ['margin', 'padding', 'border', 'color'], 0),
    _BankQuestion('Which layout system uses flexible rows and columns?', ['Flexbox', 'SQL', 'JSON', 'HTTP'], 0),
  ],
  'React': [
    _BankQuestion('React is mainly used to build?', ['User interfaces', 'Database tables', 'Operating systems', 'CSS files only'], 0),
    _BankQuestion('React UI building blocks are called?', ['Components', 'Queries', 'Tables', 'Threads'], 0),
    _BankQuestion('Which hook stores component state?', ['useState', 'useSQL', 'useHTML', 'useClass'], 0),
    _BankQuestion('What does JSX allow?', ['HTML-like syntax in JavaScript', 'SQL inside CSS', 'Java inside Python', 'Only images'], 0),
    _BankQuestion('How should React lists use keys?', ['A stable unique value', 'The same value always', 'No value', 'A CSS color'], 0),
  ],
};

final _nonDevelopmentBank = <String, List<_BankQuestion>>{
  for (final entry in _topicFacts.entries) entry.key: _fiveQuestionQuiz(entry.key, entry.value),
};

List<_BankQuestion> _fiveQuestionQuiz(String topic, List<String> facts) => [
  _BankQuestion('What is a key concept in $topic?', [facts[0], 'Skipping planning', 'Ignoring users', 'Using unrelated content'], 0),
  _BankQuestion('A beginner learning $topic should understand:', [facts[1], 'Only advanced tools', 'Nothing about goals', 'Unrelated programming'], 0),
  _BankQuestion('Which practice supports good $topic work?', [facts[2], 'Guessing without review', 'Avoiding feedback', 'Removing all details'], 0),
  _BankQuestion('When working on $topic, focus on:', [facts[3], 'Random decisions only', 'Copying unrelated work', 'No measurable outcome'], 0),
  _BankQuestion('A useful outcome of $topic is:', [facts[4], 'Confusing the audience', 'Skipping all evaluation', 'Avoiding improvement'], 0),
];

const _topicFacts = <String, List<String>>{
  'UI Design': ['Clear visual layout', 'Hierarchy of elements', 'Consistent components', 'Usable interface controls', 'Easy user interaction'],
  'UX Research': ['Understanding user needs', 'User interviews and observation', 'Testing assumptions', 'Evidence-based decisions', 'Better user experiences'],
  'Figma': ['Collaborative interface design', 'Frames and components', 'Reusable design assets', 'Interactive prototypes', 'Shareable design files'],
  'Adobe XD': ['Interface and prototype design', 'Artboards and layouts', 'Reusable components', 'Prototype links', 'Design sharing'],
  'Wireframing': ['A simple page blueprint', 'Content and layout planning', 'Low-detail structure', 'Screen flow planning', 'Early feedback'],
  'Prototyping': ['A testable product model', 'Interaction flow', 'Clickable screens', 'User testing', 'Validation before development'],
  'Typography': ['Readable text styling', 'Font size and hierarchy', 'Consistent type choices', 'Legibility', 'Clear communication'],
  'Color Theory': ['Meaningful color combinations', 'Contrast and harmony', 'Color palette selection', 'Accessible contrast', 'Visual emphasis'],
  'Design Systems': ['Reusable design standards', 'Shared components', 'Consistent patterns', 'Documentation', 'Faster consistent design'],
  'Accessibility': ['Design usable by everyone', 'Keyboard and screen-reader support', 'Sufficient contrast', 'Inclusive interaction', 'Equal access'],
  'SEO': ['Improving search visibility', 'Relevant keywords', 'Useful page content', 'Search-friendly structure', 'Organic traffic'],
  'Social Media': ['Audience engagement on platforms', 'Platform-specific content', 'Regular posting strategy', 'Community interaction', 'Brand awareness'],
  'Content Marketing': ['Useful content for an audience', 'Audience needs', 'Relevant articles or media', 'Consistent value', 'Trust and leads'],
  'Email Marketing': ['Targeted email communication', 'Subscriber permission', 'Useful email content', 'Clear calls to action', 'Customer retention'],
  'Digital Marketing': ['Marketing through digital channels', 'Online audience targeting', 'Campaign planning', 'Measurable performance', 'Business growth'],
  'Google Ads': ['Paid search advertising', 'Keyword targeting', 'Relevant ad copy', 'Budget management', 'Qualified traffic'],
  'Branding': ['A clear business identity', 'Consistent brand message', 'Recognizable visual identity', 'Audience trust', 'Market distinction'],
  'Marketing Analytics': ['Measuring campaign performance', 'Relevant metrics', 'Data interpretation', 'Evidence-based improvement', 'Better marketing decisions'],
  'Influencer Marketing': ['Partnering with trusted creators', 'Relevant audience fit', 'Authentic collaboration', 'Campaign measurement', 'Audience reach'],
  'Copywriting': ['Persuasive written communication', 'Audience-focused language', 'Clear benefits', 'Strong calls to action', 'More conversions'],
  'Entrepreneurship': ['Creating and growing a venture', 'A customer problem', 'Testing a business idea', 'Value creation', 'A sustainable business'],
  'Management': ['Coordinating people and resources', 'Clear goals', 'Planning and delegation', 'Team performance', 'Organizational results'],
  'Leadership': ['Guiding and inspiring people', 'A shared vision', 'Good communication', 'Responsible decisions', 'Motivated teams'],
  'Finance': ['Managing money and investments', 'Income and expenses', 'Budget planning', 'Financial decisions', 'Financial stability'],
  'Accounting': ['Recording financial transactions', 'Accurate records', 'Debits and credits', 'Financial reporting', 'Reliable business information'],
  'Project Management': ['Planning and delivering project work', 'Scope and goals', 'Schedules and tasks', 'Risk management', 'Successful delivery'],
  'Human Resources': ['Managing people at work', 'Fair recruitment', 'Employee development', 'Workplace policies', 'A healthy workforce'],
  'Sales': ['Helping customers buy a solution', 'Customer needs', 'Clear product value', 'Relationship building', 'Revenue growth'],
  'Business Strategy': ['Long-term business direction', 'Competitive position', 'Clear priorities', 'Resource allocation', 'Sustainable advantage'],
  'Operations': ['Running daily business processes', 'Efficient workflows', 'Quality control', 'Resource coordination', 'Reliable delivery'],
  'Communication': ['Clear exchange of information', 'Audience awareness', 'Active listening', 'Simple language', 'Mutual understanding'],
  'Public Speaking': ['Presenting clearly to an audience', 'A structured message', 'Practice and preparation', 'Confident delivery', 'Audience engagement'],
  'Career Skills': ['Professional workplace development', 'Clear career goals', 'Relevant strengths', 'Continuous learning', 'Career progress'],
  'Study Skills': ['Effective learning methods', 'A study plan', 'Active recall', 'Focused practice', 'Better understanding'],
  'Productivity': ['Using time and effort effectively', 'Clear priorities', 'Focused task management', 'Reducing distractions', 'Consistent progress'],
};

class CourseVerificationFailure implements Exception {
  const CourseVerificationFailure(this.message);
  final String message;
}
