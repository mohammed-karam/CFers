import 'dart:convert';

/// Everything the app says to Codeforces' submit page, in the page's own
/// language.
///
/// The screen loads `codeforces.com/problemset/submit` in a web view and then
/// runs these two scripts inside it: the first fills the form with the
/// problem, the language and the code the student already typed in the app,
/// the second presses the page's own Submit button. Both answer back over the
/// `CfSubmit` JavaScript channel, so the app knows what the page did.
///
/// Nothing here logs in or posts behind the student's back — the page, and
/// therefore Codeforces, stays in charge of the submission itself.

/// Which entry of Codeforces' language list the editor language stands for.
///
/// The numeric ids Codeforces assigns (`programTypeId`) are renumbered as the
/// judge is updated, so the page's own dropdown is matched by name instead:
/// [cfPrefillScript] picks the newest option whose text fits the hint.
String cfLanguageHint(String displayName) => switch (displayName) {
      'C++' => 'cpp',
      'C' => 'c',
      'Python 3' => 'python3',
      'Java' => 'java',
      'Rust' => 'rust',
      'Go' => 'go',
      'C#' => 'csharp',
      _ => '',
    };

/// Fills in the submit form: which problem, which language, which code.
///
/// Reports what it managed through the channel as
/// `{"step":"prefill","problem":…,"language":…,"source":…,"chosen":…}`.
String cfPrefillScript({
  required String problemCode,
  required String source,
  required String language,
}) {
  return r'''
(function () {
  var post = function (payload) {
    try { CfSubmit.postMessage(JSON.stringify(payload)); } catch (e) {}
  };
  var fire = function (el) {
    try {
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    } catch (e) {}
  };
  var out = { step: 'prefill', problem: false, language: false, source: false, chosen: '' };

  var code = '''+ jsonEncode(problemCode) + r''';
  var src = '''+ jsonEncode(source) + r''';

  // The code lives in a textarea even while the Ace editor is on screen, so
  // fill both and let Codeforces' own change handler keep them in step.
  var area = document.querySelector('textarea[name=source], #sourceCodeTextarea');
  if (area) {
    area.value = src;
    fire(area);
    out.source = true;
    try {
      if (window.ace && document.getElementById('editor')) {
        window.ace.edit('editor').setValue(src, -1);
      }
    } catch (e) {}
  }

  // The problem: the problemset submit page carries it as a text field
  // holding "1850C"; a contest submit page uses a dropdown of indexes.
  var field = document.querySelector('input[name=submittedProblemCode]');
  if (field) {
    field.value = code;
    fire(field);
    out.problem = true;
  } else {
    var select = document.querySelector('select[name=submittedProblemIndex]');
    if (select) {
      var wanted = code.replace(/^[0-9]+/, '');
      for (var i = 0; i < select.options.length; i++) {
        if (select.options[i].value === wanted) {
          select.selectedIndex = i;
          fire(select);
          out.problem = true;
          break;
        }
      }
    }
  }

  // The language: newest matching option wins, because Codeforces lists its
  // compilers oldest first and retires the old ones over time.
  var hint = '''+ jsonEncode(language) + r''';
  var langSelect = document.querySelector('select[name=programTypeId]');
  if (langSelect && hint) {
    var patterns = {
      cpp: [/GNU G\+\+2/i, /G\+\+17/i, /Clang\+\+17/i, /\+\+/],
      c: [/^GNU C[0-9]/i, /^Clang C/i, /^C[0-9]/],
      python3: [/^Python 3/i],
      java: [/^Java 1/i, /^Java /i],
      rust: [/^Rust/i],
      go: [/^Go /i, /^Go$/i],
      csharp: [/^C#/i]
    };
    var rules = patterns[hint] || [];
    var chosen = null;
    for (var r = 0; r < rules.length && !chosen; r++) {
      for (var j = langSelect.options.length - 1; j >= 0; j--) {
        if (rules[r].test(langSelect.options[j].text)) {
          chosen = langSelect.options[j];
          break;
        }
      }
    }
    if (chosen) {
      langSelect.value = chosen.value;
      fire(langSelect);
      out.language = true;
      out.chosen = chosen.text;
    }
  }

  post(out);
  return JSON.stringify(out);
})();
''';
}

/// Presses the page's own Submit button, so Codeforces validates the form and
/// sends it exactly as it would for a student tapping the site themselves.
///
/// Answers `{"step":"click","ok":true}` or `{"step":"click","ok":false,
/// "why":…}` — never a silent failure, the screen then tells the student to
/// tap the button on the page and keeps watching for the verdict anyway.
String cfClickSubmitScript() => r'''
(function () {
  var post = function (payload) {
    try { CfSubmit.postMessage(JSON.stringify(payload)); } catch (e) {}
  };
  var button = document.querySelector(
    'form.submit-form input.submit, .submit-form input[type=submit], input.submit[type=submit]'
  );
  if (!button) {
    post({ step: 'click', ok: false, why: 'The Submit button is not on this page yet.' });
    return 'missing';
  }
  if (button.disabled) {
    post({ step: 'click', ok: false, why: 'Codeforces has not enabled Submit yet — pick the problem on the page.' });
    return 'disabled';
  }
  button.click();
  post({ step: 'click', ok: true });
  return 'ok';
})();
''';
