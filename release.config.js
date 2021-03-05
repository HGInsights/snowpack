/* eslint-disable no-param-reassign */
const commitAnalyzerOptions = {
  preset: 'angular',
  releaseRules: [
    { type: 'breaking', release: 'major' },
    { type: 'refactor', release: 'patch' },
    { type: 'config', release: 'patch' },
    { scope: 'chore', release: false },
    { scope: 'no-release', release: false },
    { scope: 'test', release: false },
  ],
  parserOpts: {
    noteKeywords: ['BREAKING CHANGE', 'BREAKING CHANGES'],
  },
};

const releaseNotesGeneratorOptions = {
  writerOpts: {
    transform: (commit) => {
      if (commit.type === 'breaking') {
        commit.type = 'Breaking';
      } else if (commit.type === 'feat') {
        commit.type = 'Features';
      } else if (commit.type === 'fix') {
        commit.type = 'Bug Fixes';
      } else if (commit.type === 'refactor') {
        commit.type = 'Code Refactoring';
      } else if (commit.type === 'chore') {
        commit.type = 'Chores';
      } else if (commit.type === 'config') {
        commit.type = 'Config';
      } else if (commit.type === 'test') {
        commit.type = 'Tests';
      } else if (commit.type === 'docs') {
        commit.type = 'Documentation';
      } else if (commit.type === 'no-release') {
        return;
      }
      if (typeof commit.hash === 'string') {
        commit.shortHash = commit.hash.substring(0, 7);
      }

      // eslint-disable-next-line consistent-return
      return commit;
    },
  },
};

const execCommands = {
  // eslint-disable-next-line no-template-curly-in-string
  verifyReleaseCmd: 'echo ${nextRelease.version} > version',
};

module.exports = {
  plugins: [
    // analyze commits with conventional-changelog
    ['@semantic-release/commit-analyzer', commitAnalyzerOptions],
    // generate changelog content with conventional-changelog
    ['@semantic-release/release-notes-generator', releaseNotesGeneratorOptions],
    // updates the changelog file
    '@semantic-release/changelog',
    '@semantic-release/git',
    // creating a git tag
    '@semantic-release/github',
    // run events commands
    ['@semantic-release/exec', execCommands],
  ],
};
