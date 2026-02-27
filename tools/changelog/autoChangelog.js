import { parseChangelog } from "./changelogParser.js";

const safeYml = (string) =>
  string.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n");

export function changelogToYml(changelog, login) {
  const author = changelog.author || login;
  const ymlLines = [];

  ymlLines.push(`author: "${safeYml(author)}"`);
  ymlLines.push(`delete-after: True`);
  ymlLines.push(`changes:`);

  for (const change of changelog.changes) {
    ymlLines.push(
      `  - ${change.type.changelogKey}: "${safeYml(change.description)}"`,
    );
  }

  return ymlLines.join("\n");
}

// PENTEST UPDATED - This function processes a push event, identifies merged PRs, extracts changelog info, and creates a commit with changelog files for each PR. It uses GitHub's REST API to interact with the repository.
export async function processAutoChangelog({ github, context }) {
  const { owner, repo } = context.repo;

  // Compare commit range from push
  const { data: comparison } = await github.rest.repos.compareCommits({
    owner,
    repo,
    base: context.payload.before,
    head: context.payload.after,
  });

  const processedPRs = new Set();
  const filesToCreate = [];

  for (const commit of comparison.commits) {
    const { data: prs } =
      await github.rest.repos.listPullRequestsAssociatedWithCommit({
        owner,
        repo,
        commit_sha: commit.sha,
      });

    for (const pr of prs) {
      if (processedPRs.has(pr.number)) continue;
      if (!pr.merged_at) continue;

      processedPRs.add(pr.number);

      const changelog = parseChangelog(pr.body);
      if (!changelog || changelog.changes.length === 0) continue;

      const yml = changelogToYml(changelog, pr.user.login);

      filesToCreate.push({
        path: `html/changelogs/AutoChangeLog-pr-${pr.number}.yml`,
        content: yml,
      });
    }
  }

  if (filesToCreate.length === 0) {
    console.log("No changelogs found in this push.");
    return;
  }

  // Get current HEAD commit
  const { data: headCommit } = await github.rest.git.getCommit({
    owner,
    repo,
    commit_sha: context.payload.after,
  });

  // Create blobs
  const blobs = [];
  for (const file of filesToCreate) {
    const { data: blob } = await github.rest.git.createBlob({
      owner,
      repo,
      content: file.content,
      encoding: "utf-8",
    });

    blobs.push({
      path: file.path,
      mode: "100644",
      type: "blob",
      sha: blob.sha,
    });
  }

  // Create new tree
  const { data: newTree } = await github.rest.git.createTree({
    owner,
    repo,
    base_tree: headCommit.tree.sha,
    tree: blobs,
  });

  // Create commit
  const { data: newCommit } = await github.rest.git.createCommit({
    owner,
    repo,
    message: `Automatic changelog batch for merged PRs [ci skip]`,
    tree: newTree.sha,
    parents: [context.payload.after],
  });

  // Update master ref
  await github.rest.git.updateRef({
    owner,
    repo,
    ref: "heads/master",
    sha: newCommit.sha,
  });

  console.log(`Created ${filesToCreate.length} changelog(s) in one commit.`);
}
