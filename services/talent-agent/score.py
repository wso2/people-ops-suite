from llm_utils import llm
from kor.extraction import create_extraction_chain
from schemas import candidate_skill_score_schema
import requests
import os
from dotenv import load_dotenv

load_dotenv()

chain = create_extraction_chain(llm, candidate_skill_score_schema)

def extract_repo_info(repo_url):
    try:
        parts = repo_url.strip("/").split("/")
        owner = parts[-2]
        name = parts[-1]
        return owner, name
    except Exception:
        return None, None

def analyze_github_project(repo_url):
    owner, name = extract_repo_info(repo_url)
    if not owner or not name:
        return {"error": "Invalid GitHub URL"}

    headers = {"Authorization": f"Bearer {os.getenv("GITHUB_TOKEN")}"}
    query = """
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        name
        stargazerCount
        forkCount
        updatedAt
        defaultBranchRef {
          target {
            ... on Commit {
              history(first: 100) {
                totalCount
              }
            }
          }
        }
        pullRequests(states: MERGED) {
          totalCount
        }
        readme: object(expression: "HEAD:README.md") {
          ... on Blob {
            text
          }
        }
      }
    }
    """

    variables = {"owner": owner, "name": name}

    response = requests.post(
        os.getenv("GITHUB_API_URL"),
        json={"query": query, "variables": variables},
        headers=headers,
    )

    resp_json = response.json()

    if "errors" in resp_json:
        print("GraphQL Error:", resp_json["errors"])
        return {""}

    if "data" not in resp_json or not resp_json["data"].get("repository"):
        print("Repository not found or inaccessible.")
        return {""}

    repo = resp_json["data"]["repository"]

    return {
        "stars": repo["stargazerCount"],
        "forks": repo["forkCount"],
        "last_updated": repo["updatedAt"],
        "commits": repo["defaultBranchRef"]["target"]["history"]["totalCount"],
        "merged_prs": repo["pullRequests"]["totalCount"],
    }

def evaluate_candidate(
    candidate,
    skills,
    experience_weight=0.4,
    certification_weight=0.2,
    project_weight=0.4,
):
    """
    Evaluates a candidate based on a set of skills using a weighted scoring system.

    Args:
        candidate: Dictionary containing candidate information
        skills: List of skills to evaluate
        experience_weight: Weight for experience score (default: 0.4)
        certification_weight: Weight for certification score (default: 0.2)
        project_weight: Weight for project score (default: 0.4)

    Returns:
        List of float scores for each skill (0.0-10.0 scale)
    """
    results = []

    experience = candidate.get("experience", [])
    certifications = candidate.get("certifications", [])
    projects = candidate.get("projects", [])
    education = candidate.get("education", [])

    for skill in skills:
        exp_text = format_experience(experience, skill)
        cert_text = format_certifications(certifications, skill)
        project_text = format_projects(projects, skill)
        edu_text = format_education(education, skill)

        input_text = f"""
        Evaluate the candidate's proficiency in: {skill}
        
        Evaluation criteria:
        1. Experience: Years and relevance of experience using this skill (0-10)
        2. Certifications: Relevant certifications and their recognition level (0-10)
        3. Projects: Complexity and relevance of projects utilizing this skill (0-10)
        4. Education: Relevant formal education related to this skill (0-10)
        
        Candidate information:
        - Experience: {exp_text}
        - Certifications: {cert_text}
        - Projects: {project_text}
        - Education: {edu_text}
        
        Please provide detailed scores for each criterion and a final weighted score.
        """

        evaluation = chain.invoke(input_text)["data"]["candidate_skill_score"][0]

        experience_score = float(evaluation.get("experience_score", 0.0))
        certification_score = float(evaluation.get("certification_score", 0.0))
        project_score = float(evaluation.get("project_score", 0.0))
        education_score = float(evaluation.get("education_score", 0.0))

        weighted_score = (
            experience_score * experience_weight
            + certification_score * certification_weight
            + project_score * project_weight
        )

        normalized_score = min(10.0, max(0.0, weighted_score))

        skill_result = {
            "skill": skill,
            "similarityScore": round(normalized_score, 2),
            "supportingPoints": evaluation.get("evaluation_text", ""),
        }

        results.append(skill_result)

    return results


def format_experience(experience, skill):
    """Format experience entries, highlighting those relevant to the skill"""
    if not experience:
        return "None"

    relevant_exp = []
    for exp in experience:
        role = exp.get("job_title", "")
        company = exp.get("company", "")

        exp_text = f"{role} at {company}"

        relevant_exp.append(exp_text)

    return "\n".join(relevant_exp)


def format_certifications(certifications, skill):
    """Format certifications, highlighting those relevant to the skill"""
    if not certifications:
        return "None"

    cert_list = []
    for cert in certifications:
        name = cert.get("name", "")
        issuer = cert.get("issued_by", "")

        skill_mentioned = skill.lower() in name.lower()

        cert_text = f"{name} from {issuer}"
        if skill_mentioned:
            cert_text = f"[RELEVANT] {cert_text}"

        cert_list.append(cert_text)

    return "\n".join(cert_list)


def format_projects(projects, skill):
    """Format projects, highlighting those relevant to the skill"""
    if not projects:
        return "None"

    project_list = []
    for project in projects:
        name = project.get("name", "")
        description = project.get("description", "")
        tech_stack = project.get("technologies", [])
        github_link = project.get("github", "")

        skill_mentioned = (
            skill.lower() in description.lower()
            or skill.lower() in " ".join(tech_stack).lower()
        )

        tech_text = ", ".join(tech_stack) if tech_stack else "Not specified"
        project_text = f"{name}: {description} (Technologies: {tech_text})"
        if skill_mentioned:
            project_text = f"[RELEVANT] {project_text}"

        if github_link:
            project_text += f" [GitHub Info About the project: {analyze_github_project(github_link)}]"

        project_list.append(project_text)

    return "\n".join(project_list)


def format_education(education, skill):
    """Format education entries, highlighting those relevant to the skill"""
    if not education:
        return "None"

    edu_list = []
    for edu in education:
        degree = edu.get("degree", "")
        institution = edu.get("institution", "")
        gpa = edu.get("gpa_zscore", "")

        skill_mentioned = skill.lower() in degree.lower()

        edu_text = (
            f"{degree} from {institution}. GPA(out of 4 or 4.2) or Z_score: {gpa}"
        )
        if skill_mentioned:
            edu_text = f"[RELEVANT] {edu_text}"

        edu_list.append(edu_text)

    return "\n".join(edu_list)
