import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/data/parsers/statement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixture shaped like a real Codeforces problem page: header with limits,
/// TeX spans, section titles, sample lines stored as <div>s, and a note.
const String _statementHtml = r'''
<!DOCTYPE html>
<html>
  <body>
    <div class="problem-statement">
      <div class="header">
        <div class="title">A. Keanu Reeves</div>
        <div class="time-limit">
          <div class="property-title">time limit per test</div>
          1 second
        </div>
        <div class="memory-limit">
          <div class="property-title">memory limit per test</div>
          256 megabytes
        </div>
        <div class="input-file">standard input</div>
        <div class="output-file">standard output</div>
      </div>
      <p>You are given a string <span class="tex-span">\(s\)</span>
         consisting of <span class="tex-span">\(n\)</span> digits.</p>
      <div class="section-title">Input</div>
      <p>The first line contains <span class="tex-span">\(n\)</span>.</p>
      <div class="section-title">Output</div>
      <p>Print one integer.</p>
      <div class="sample-tests">
        <div class="sample-test">
          <div class="input">
            <div class="title">Input</div>
            <pre><div class="test-example-line test-example-line-even">4</div><div class="test-example-line test-example-line-odd">12 3 4 5</div></pre>
          </div>
          <div class="output">
            <div class="title">Output</div>
            <pre>10
</pre>
          </div>
        </div>
      </div>
      <div class="note">
        <div class="section-title">Note</div>
        <p>In the first test the answer is <span class="tex-span">\(1+2+3+4\)</span>.</p>
      </div>
    </div>
  </body>
</html>
''';

/// A statement in the markup Codeforces uses today: maths written as raw TeX
/// between triple dollars, and a picture wrapped in a caption.
const String _mathStatementHtml = r'''
<div class="problem-statement">
  <div class="header">
    <div class="title">G. Path Prefixes</div>
    <div class="time-limit">
      <div class="property-title">time limit per test</div>
      3 seconds
    </div>
  </div>
  <p>It contains $$$n$$$ vertices, numbered from $$$1$$$ to $$$n$$$.</p>
  <p>The first line contains $$$t$$$ ($$$1 \le t \le 10^4$$$) test cases and
     $$$2\cdot10^5$$$ vertices, so $$$100 \gt 2$$$ holds.</p>
  <p>Output $$$r_2, r_3, \dots, r_n$$$ where $$$\int_0^1 x^2$$$ and
     $$$\frac{\frac{a}{b}}{c}$$$ of the prefixes.</p>
  <center>
    <img class="tex-graphics" src="//espresso.codeforces.com/abc.png">
    <span class="tex-font-size-small">Example for $$$n=9$$$.</span>
  </center>
  <div class="sample-tests">
    <div class="sample-test">
      <div class="input"><div class="title">Input</div><pre>2
$5
</pre></div>
      <div class="output"><div class="title">Output</div><pre>10
</pre></div>
    </div>
  </div>
</div>
''';

/// Plain-text sample (no line <div>s), a list, and a line break.
const String _altStatementHtml = r'''
<div class="problem-statement">
  <div class="header">
    <div class="title">B. Broken keyboard</div>
  </div>
  <p>Line one.<br>Line two.</p>
  <ul>
    <li>first item</li>
    <li>second item</li>
  </ul>
  <div class="sample-tests">
    <div class="sample-test">
      <div class="input"><pre>a
b</pre></div>
      <div class="output"><pre>x
y</pre></div>
    </div>
  </div>
</div>
''';

void main() {
  const parser = StatementParser();

  group('StatementParser', () {
    test('reads the title and the limits out of the header', () {
      final statement = parser.parse(_statementHtml);

      expect(statement.title, 'A. Keanu Reeves');
      expect(statement.timeLimit, '1 second');
      expect(statement.memoryLimit, '256 megabytes');
    });

    test('turns paragraphs, sections, samples and notes into blocks', () {
      final statement = parser.parse(_statementHtml);
      final blocks = statement.blocks;

      expect(blocks.first, isA<StatementParagraph>());
      expect(
        (blocks.first as StatementParagraph).text,
        contains('string s'),
      );
      // TeX delimiters are gone from the readable text.
      expect((blocks.first as StatementParagraph).text, isNot(contains(r'\(')));

      final headings =
          blocks.whereType<StatementHeading>().map((b) => b.text).toList();
      expect(headings, ['Input', 'Output', 'Note']);

      final samples = blocks.whereType<StatementSample>();
      expect(samples, hasLength(1));
      final sample = samples.single;
      expect(sample.input, '4\n12 3 4 5');
      expect(sample.output, '10');

      final last = blocks.last;
      expect(last, isA<StatementParagraph>());
      expect((last as StatementParagraph).text, contains('1+2+3+4'));
    });

    test('keeps plain sample text, lists and line breaks intact', () {
      final statement = parser.parse(_altStatementHtml);

      expect(statement.title, 'B. Broken keyboard');

      final paragraph =
          statement.blocks.whereType<StatementParagraph>().first.text;
      expect(paragraph, contains('Line one.'));
      expect(paragraph, contains('Line two.'));

      final list = statement.blocks.whereType<StatementList>().single;
      expect(list.items, ['first item', 'second item']);
      expect(list.ordered, isFalse);

      final sample = statement.blocks.whereType<StatementSample>().single;
      expect(sample.input, 'a\nb');
      expect(sample.output, 'x\ny');
    });

    test('rejects a page that carries no problem statement', () {
      expect(
        () => parser.parse('<html><body>captcha</body></html>'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('problem statement'),
          ),
        ),
      );
    });

    test('plainText hands the whole problem to the AI checker', () {
      final text = parser.parse(_statementHtml).plainText;

      expect(text, startsWith('A. Keanu Reeves'));
      expect(text, contains('time limit 1 second'));
      expect(text, contains('Input'));
      expect(text, contains('4\n12 3 4 5'));
      expect(text, contains('10'));
    });

    test(r'turns the $$$…$$$ maths Codeforces writes into readable text', () {
      final statement = parser.parse(_mathStatementHtml);
      final text = statement.blocks
          .whereType<StatementParagraph>()
          .map((block) => block.text)
          .join('\n');

      // No delimiters and no TeX commands left for the student to decode.
      expect(text, isNot(contains(r'$$$')));
      expect(text, isNot(contains(r'\le')));
      expect(text, isNot(contains(r'\gt')));
      expect(text, isNot(contains(r'\dots')));
      expect(text, isNot(contains(r'\cdot')));

      expect(text, contains('n vertices, numbered from 1 to n'));
      expect(text, contains('(1 ≤ t ≤ 10^4) test cases'));
      expect(text, contains('2·10^5 vertices, so 100 > 2 holds'));
      expect(text, contains('r_2, r_3, …, r_n'));
      expect(text, contains('∫_0^1 x^2'));
      expect(text, contains('((a)/(b))/(c)'));
    });

    test('leaves sample data alone, dollars and all', () {
      final statement = parser.parse(_mathStatementHtml);
      final sample = statement.blocks.whereType<StatementSample>().single;

      expect(sample.input, '2\n\$5');
      expect(sample.output, '10');
    });

    test('keeps a picture that is wrapped in a caption', () {
      final statement = parser.parse(_mathStatementHtml);

      expect(
        statement.blocks.whereType<StatementImage>().single.src,
        'https://espresso.codeforces.com/abc.png',
      );
      expect(
        statement.blocks
            .whereType<StatementParagraph>()
            .map((block) => block.text)
            .join(' '),
        contains('Example for n=9'),
      );
    });
  });

  group('ProblemRef', () {
    test('reads a Codeforces problemset entry', () {
      final problem = ProblemRef.fromJson(<String, dynamic>{
        'contestId': 1850,
        'index': 'C',
        'name': 'Roman and Numbers',
        'rating': 1800,
        'tags': ['math', 'number theory'],
        'type': 'PROGRAMMING',
      });

      expect(problem.id, '1850C');
      expect(problem.code, '1850 C');
      expect(problem.rating, 1800);
      expect(problem.tags, ['math', 'number theory']);
      expect(
        problem.statementUrl,
        'https://codeforces.com/problemset/problem/1850/C',
      );
    });

    test('tolerates a missing rating and tags', () {
      final problem = ProblemRef.fromJson(<String, dynamic>{
        'contestId': 1,
        'index': 'A',
        'name': 'Theatre Square',
      });

      expect(problem.rating, isNull);
      expect(problem.tags, isEmpty);
    });

    test('refuses an entry without an id', () {
      expect(
        () => ProblemRef.fromJson(<String, dynamic>{'name': 'orphan'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
