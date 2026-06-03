import {
  author,
  description,
  license,
  name,
  repository,
  version,
} from "../../package.json";

const getDefaultBranch = () => {
  const envBranch = process.env.DEFAULT_BRANCH || process.env.GITHUB_REF_NAME;
  if (envBranch) {
    return envBranch.replace(/^refs\/heads\//, "");
  }
  return "main";
};

const makeLicenseUrl = () => {
  const repoUrl = new URL(repository.url);
  const repoPath = repoUrl.pathname.replace(/\/$/, "");
  const licensePath = `${repoPath}/blob/${getDefaultBranch()}/LICENSE`;
  return new URL(licensePath, repoUrl).toString();
};

export const getProjectName = () => {
  return name
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
};

export const getProjectInfo = () => {
  return {
    title: getProjectName(),
    description,
    version,
    contact: {
      name: author.name,
      email: author.email,
      url: author.url,
    },
    license: {
      url: makeLicenseUrl(),
      name: license,
    },
  };
};
