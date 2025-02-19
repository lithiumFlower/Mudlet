# New to Git?
If you don't have previous Git experience, we highly recommend downloading and installing
the free [Github for Desktop](https://desktop.github.com) app to contribute code to Mudlet 🌟

# Coding guidelines

If you're a first-timer, you're excluded, we'll go easy on you :wink:

## Use QLatin1String over qsl (a *shorter* preprocessor macro we define for Qt's own `QStringLiteral` macro) if the function takes it

Some methods in the Qt API have overloads for either taking a QString, or a QLatin1String object.
This is because Latin1 is simpler to parse than UTF-16, and therefore the QLatin1String version can
be faster, and use less memory. For example, QString::startsWith() has the following declarations:

```
bool	startsWith(const QString &s, Qt::CaseSensitivity cs = Qt::CaseSensitive) const
bool	startsWith(const QStringRef &s, Qt::CaseSensitivity cs = Qt::CaseSensitive) const
bool	startsWith(QLatin1String s, Qt::CaseSensitivity cs = Qt::CaseSensitive) const
bool	startsWith(QChar c, Qt::CaseSensitivity cs = Qt::CaseSensitive) const
```

Notice how the 3rd variant accepts a `QLatin1String`? That means you can use it. `==` and `+=` also
accept it, so here are some examples:

```cpp
bool same = (str == QLatin1String("Hello"));
str.startsWith(QLatin1String("Hello"));
str += QLatin1String("World");
```

Examples above are more efficient than:

```cpp
bool same = (str == qsl("Hello"));
str.startsWith(qsl("Hello"));
str += qsl("World");
```

And even more than:

```cpp
bool same = (str == "Hello");
str.startsWith("Hello");
str += "World";
```

Not all functions are going to accept `QLatin1String` - `QIcon` constructors for example are the following:

```
QIcon()
QIcon(const QPixmap &pixmap)
QIcon(const QIcon &other)
QIcon(QIcon &&other)
QIcon(const QString &fileName)
QIcon(QIconEngine *engine)
```

No `QLatin1String` - mentioned - so use `qsl` instead, which creates us a `QString()` at compile-time so at least creating the object is faster.

([source](http://blog.qt.io/blog/2014/06/13/qt-weekly-13-qstringliteral/),
 [additional reading](https://woboq.com/blog/qstringliteral.html))

## Do not use ``qsl("")``

Prefer ``QString()`` over ``qsl("")`` for  for empty strings - the default constructor
for QString is cheaper in terms of both instructions and memory.

([source](http://blog.qt.io/blog/2014/06/13/qt-weekly-13-qstringliteral/))

## Avoid duplicated QStringLiterals

Avoid having multiple QStringLiterals with the same content. For plain literals and QLatin1String, compilers
try to consolidate identical literals so that they are not duplicated. For qsl, identical strings
cannot be merged.

([source](http://blog.qt.io/blog/2014/06/13/qt-weekly-13-qstringliteral/))

## Use .arg(arg1, arg2) instead of .arg(arg1).arg(arg2)

If you just need to use a plain .arg() call, use multiple arguments within it and not as separate .arg() calls as that'll avoid creating temporary QString objects. If your 2nd and 3rd arguments happen to be numbers, be sure to wrap them in  `QString::number(yourNumber)`.

([source](https://meetingcpp.com/tl_files/mcpp/2015/talks/Marc-Mutz-MC++15-Effective-Qt.pdf))

# Internationalization do's and don'ts

Do:
* enable strings visible in the Mudlet GUI to be translateable
* minimise use of HTML styling tags in strings to be translated
* enable users to use language-specific Mudlet object names (triggers, aliases, labels, etc)

Don't:
* translate the Mudlet API: functions, events, error messages or constants (e.g. `main` console)
* use numbers in the API - English words are preferred instead
* try to assemble a sentence on the fly - English grammar does not translate into other languages. Present the full sentence to translators instead
* assume English-centric plural forms, other languages do not necessarily have the simple add an "s"/"es" for more/less then the singular case.
* assume universal quote and number punctuation formats. There are languages that use « and » instead of " for "quoting" words or phrases. Qt can provide Locale specific displays of numbers/dates/times.

# Git commit guidelines for core team

## Refactoring

* Refactors for linting or formatting should be their own PRs
* Do not change code in code paths which are not a part of the PR
  * If it needs to be refactored, it deserves to be its own PR

## Danger enforced PR requirements

* PR Title must start with `fix`, `improve`, `add`, or `infra`
  * This facilitates automatic changelog gathering and categorization
  * Cannot merge until it is fixed: core team can always adjust it before merging
* Any new TODO in a source file must have a Mudlet github issue on the same line
  * good:
    * //TODO: https://github.com/Mudlet/Mudlet/issues/1234
  * bad:
    * //TODO: a thing we aren't actually tracking with an issue

Danger will also give a heads up if the PR title is long, or if more than 10 source files are changed in a single PR. These are not blocked but the warnings should serve to draw attention to something which may require a double check. More info below.

## Mega PRs

Pull Requests that overhaul large pieces of functionality at once will not be accepted: through experience, they bring more pain than they are worth. Being really difficult to discuss, test, and reason about, they are banned.

That does not mean we don't welcome large overhauls: we do. Just make sure to send it in as separate, logically broken-down improvements that implement the functionality you'd like to have in a step process.

Of course, before embarking on such a journey, [discuss with the core team](https://discord.gg/kuYvMQ9) your ideas first so we can guide you on the best design!

## Merging Pull Requests (PRs)

The preferred order of [merging PRs](https://help.github.com/articles/about-pull-request-merges/) is:
1. Prefer _squash and merge_ for a clean history and added PR numbers for details of discussion for future comparison.
2. Else _rebase and merge_ if you'd like to keep the history, but know this will not link to the PR in public test builds' (PTB) changelogs, etc.
3. Avoid creating a _merge commit_.

## Merging auto-generated translation PRs

PRs auto-opened by [mudlet-machine-account](https://github.com/mudlet-machine-account) with new translation strings can be approved and merged right away by anyone on the core team.

The idea is to use Crowdin as a single source of truth for translation - if there's an issue with a translation, let's discuss it in Crowdin.
