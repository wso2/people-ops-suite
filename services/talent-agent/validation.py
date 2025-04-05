import json
import re

from llm_utils import llm
from utils import printOutput
from utils import validate_year

output = {
    "candidate": {
        "certifications": [
            {
                "issued_by": "DeepLearning.AI",
                "link": "",
                "name": "Natural Language Processing Specialization",
                "year": None,
            },
            {
                "issued_by": "Nvidia Deep Learning Institute",
                "link": "",
                "name": "GPU Acceleration with the C++ Standard Library",
                "year": None,
            },
            {
                "issued_by": "Nvidia Deep Learning Institute",
                "link": "",
                "name": "Getting Started with Accelerated Computing in CUDA C/C++",
                "year": None,
            },
            {
                "issued_by": "Kaggle Learn",
                "link": "",
                "name": "Computer Vision & Machine Learning Explainability",
                "year": None,
            },
            {
                "issued_by": "AWS Academy",
                "link": "",
                "name": "Machine Learning Foundations",
                "year": None,
            },
        ],
        "educations": [
            {
                "degree": "B.Sc. (Hons) in Computer Science and Engineering",
                "end_year": None,
                "gpa_zscore": 3.9643,
                "institution": "University of Moratuwa",
                "location": "Moratuwa, Sri Lanka",
                "start_year": 2022,
            },
            {
                "degree": "G.C.E. AL Examination - Physical Science Stream",
                "end_year": 2020,
                "gpa_zscore": 2.7876,
                "institution": "Royal College",
                "location": "Colombo 07, Sri Lanka",
                "start_year": 2020,
            },
        ],
        "experiences": [],
        "interests": [
            {"interest": "Natural Language Processing"},
            {"interest": "Computer Vision"},
            {"interest": "Computer graphics"},
            {"interest": "3D Modeling"},
            {"interest": "Number Theory"},
            {"interest": "Real Analysis"},
            {"interest": "Game Theory"},
            {"interest": "Stoicism"},
        ],
        "languages": [
            {"language": "English", "proficiency": ""},
            {"language": "Sinhala", "proficiency": ""},
        ],
        "personal_info": {
            "address": "Wadduwa",
            "country": "Sri Lanka",
            "email": "dulina.21@cse.mrt.ac.lk",
            "full_name": "Mukundadura Dulina Banmitha Perera",
            "phone": "+94 702632639",
        },
        "professional_links": {
            "bitbucket": "",
            "devto": "",
            "github": "https://github.com/Dulina-Perera",
            "gitlab": "",
            "hackerrank": "",
            "kaggle": "https://www.kaggle.com/pereradulina",
            "leetcode": "",
            "linkedin": "",
            "medium": "",
            "portfolio": "",
            "stackoverflow": "",
        },
        "projects": [
            {
                "description": "This project extracts mind maps from unstructured text documents like PDFs and LaTeX. \
                  By utilizing topic modeling and text clustering, it analyzes content to identify key themes and \
                     relationships, transforming complex information into organized visual maps.",
                "github": "https://github.com/Dulina-Perera/TopicNet",
                "name": "TopicNet",
                "technologies": [
                    {"technology": "Python"},
                    {"technology": "NLTK"},
                    {"technology": "FastAPI"},
                    {"technology": "SolidJS"},
                ],
            },
            {
                "description": "Artistry is a lightweight drawing application that allows users to create sketches \
                  through a minimalist interface, showcasing the capabilities of the Vulkan graphics API for efficient \
                     and responsive graphics applications.",
                "github": "https://github.com/Dulina-Perera/Artistry",
                "name": "Artistry",
                "technologies": [
                    {"technology": "C++"},
                    {"technology": "OpenGL"},
                    {"technology": "Vulkan"},
                ],
            },
            {
                "description": "This web project serves as a blog platform for sharing insights and tutorials on \
                  machine learning using the Julia programming language. It renders markdown files as blog posts, \
                     providing a user-friendly interface for readers interested in learning about machine learning \
                        concepts and applications in Julia.",
                "github": "https://github.com/Dulina-Perera/ML-with-Julia",
                "name": "ML-with-Julia",
                "technologies": [{"technology": "Svelte"}],
            },
            {
                "description": "CricViz scrapes data from the 2024 T20 World Cup on ESPN Cricinfo to create an \
                  interactive Power BI dashboard. It provides insights and visualizations of player performances and \
                     match statistics throughout the tournament.",
                "github": "https://github.com/Dulina-Perera/CricViz",
                "name": "CricViz",
                "technologies": [
                    {"technology": "Ruby"},
                    {"technology": "Selenium"},
                    {"technology": "Python"},
                    {"technology": "Pandas"},
                    {"technology": "Power BI"},
                ],
            },
            {
                "description": "RoadScan detects and recognizes vehicle license plates in real-time using YOLOv8 and \
                  EasyOCR. It processes video streams to extract license plate information for applications like \
                     automatic toll collection and parking management.",
                "github": "https://github.com/Dulina-Perera/RoadScan",
                "name": "RoadScan",
                "technologies": [
                    {"technology": "Python"},
                    {"technology": "OpenCV"},
                    {"technology": "YOLOv8"},
                    {"technology": "EasyOCR"},
                ],
            },
            {
                "description": "This project implements an interpreter for the RPAL language, featuring a scanner \
                  to tokenize input, a parser for grammatical analysis, and a CSE machine for evaluation. It serves \
                     as a functional programming tool for educational purposes.",
                "github": "https://github.com/Dulina-Perera/RPAL/tree/master/Interpreter",
                "name": "RPAL-Interpreter",
                "technologies": [{"technology": "C"}],
            },
            {
                "description": "C-Store is a comprehensive e-commerce platform for a single vendor, offering product \
                  management, a shopping cart for customers, and secure order processing. It aims to provide a \
                     seamless online shopping experience for small businesses.",
                "github": "https://github.com/Dulina-Perera/C-Store",
                "name": "C-Store",
                "technologies": [
                    {"technology": "SpringBoot"},
                    {"technology": "PostgreSQL"},
                    {"technology": "ReactJS"},
                ],
            },
        ],
        "skills": [
            {"skill": "Linux"},
            {"skill": "Windows"},
            {"skill": "Unix"},
            {"skill": "C"},
            {"skill": "Python"},
            {"skill": "C++"},
            {"skill": "Java"},
            {"skill": "Ruby"},
            {"skill": "Typescript"},
            {"skill": "Bash"},
            {"skill": "Pytorch"},
            {"skill": "Scikit-Learn"},
            {"skill": "Numpy"},
            {"skill": "CUDA"},
            {"skill": "OpenMP"},
            {"skill": "Selenium"},
            {"skill": "OpenGL"},
            {"skill": "Vulkan"},
            {"skill": "SpringBoot"},
            {"skill": "FastAPI"},
            {"skill": "Angular"},
            {"skill": "Svelte"},
            {"skill": "PostgreSQL"},
            {"skill": "MySQL"},
            {"skill": "Git"},
            {"skill": "GitHub"},
            {"skill": "Power BI"},
            {"skill": "Blender"},
            {"skill": "Figma"},
        ],
    }
}


def validate_candidate_data_format(data):
    if not data:
        return json.dumps({}, indent=4)
    if not data.get("candidate"):
        return json.dumps({}, indent=4)
    candidate = data["candidate"]
    if not candidate.get("personal_info") or candidate.get("personal_info") == []:
        data["candidate"]["personal_info"] = {}
    if isinstance(candidate.get("personal_info"), list):
        data["candidate"]["personal_info"] = candidate["personal_info"][0]

    if not candidate.get("educations"):
        data["candidate"]["educations"] = []
    if not isinstance(candidate.get("educations"), list):
        data["candidate"]["educations"] = [candidate["educations"]]

    if not candidate.get("skills"):
        data["candidate"]["skills"] = []
    if not isinstance(candidate.get("skills"), list):
        data["candidate"]["skills"] = [candidate["skills"]]
    data["candidate"]["skills"] = [s["skill"] for s in data["candidate"]["skills"]]

    if not candidate.get("certifications"):
        data["candidate"]["certifications"] = []
    if not isinstance(candidate.get("certifications"), list):
        data["candidate"]["certifications"] = [candidate["certifications"]]

    if not candidate.get("projects"):
        data["candidate"]["projects"] = []
    if not isinstance(candidate.get("projects"), list):
        data["candidate"]["projects"] = [candidate["projects"]]
    for project in data["candidate"]["projects"]:
        project["technologies"] = [t["technology"] for t in project["technologies"]]

    if (
        not candidate.get("professional_links")
        or candidate.get("professional_links") == []
    ):
        data["candidate"]["professional_links"] = {}
    if isinstance(candidate.get("professional_links"), list):
        data["candidate"]["professional_links"] = candidate["professional_links"][0]

    if not candidate.get("experiences"):
        data["candidate"]["experiences"] = []
    if not isinstance(candidate.get("experiences"), list):
        data["candidate"]["experiences"] = [candidate["experiences"]]

    if not candidate.get("languages"):
        data["candidate"]["languages"] = []
    if not isinstance(candidate.get("languages"), list):
        data["candidate"]["languages"] = [candidate["languages"]]

    if not candidate.get("interests"):
        data["candidate"]["interests"] = []
    if not isinstance(candidate.get("interests"), list):
        data["candidate"]["interests"] = [candidate["interests"]]
    data["candidate"]["interests"] = [
        s["interest"] for s in data["candidate"]["interests"]
    ]
    return data


def format_candidate_data(data):
    data = validate_candidate_data_format(data)

    candidate = data.get("candidate")

    if candidate.get("personal_info") != {}:
        personal_info = candidate["personal_info"]
        if personal_info.get("email") != None and personal_info.get("email") != "":
            email = personal_info["email"]
            email_regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            if not re.match(email_regex, email):
                personal_info["email"] = ""

        if personal_info.get("phone") != None and personal_info.get("phone") != "":
            phone = personal_info["phone"]
            country = personal_info.get("country", "")
            response = None
            if country != "":
                prompt = f"Format this phone number into +country_code<space>XXXXXXXXX format: {phone}. Give the \
                  formatted phone number only. For an example give +94 701684781. If country code is not available, \
                     use {country}'s code as the country code."
                response = llm.invoke(prompt)
                personal_info["phone"] = response.content if response else ""
            phone_regex = r"^\+\d{1,3}\s\d{9,10}$"
            phone_number_match = re.search(
                phone_regex, response.content if response else ""
            )
            if phone_number_match:
                personal_info["phone"] = phone_number_match.group(0)
            else:
                personal_info["phone"] = ""

    if candidate.get("professional_links") != {}:
        professional_links = candidate["professional_links"]
        for key, link in list(professional_links.items()):
            # if link:
            if key == "linkedin" and not re.match(
                r"^https?://(www\.)?linkedin\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "github" and not re.match(
                r"^https?://(www\.)?github\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "gitlab" and not re.match(
                r"^https?://(www\.)?gitlab\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "bitbucket" and not re.match(
                r"^https?://(www\.)?bitbucket\.org/.*$", link
            ):
                del professional_links[key]
            elif key == "hackerrank" and not re.match(
                r"^https?://(www\.)?hackerrank\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "leetcode" and not re.match(
                r"^https?://(www\.)?leetcode\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "devto" and not re.match(
                r"^https?://(www\.)?dev\.to/.*$", link
            ):
                del professional_links[key]
            elif key == "medium" and not re.match(
                r"^https?://(www\.)?medium\.com/.*$", link
            ):
                del professional_links[key]
            elif key == "portfolio" and not re.match(r"^https?://.*$", link):

                del professional_links[key]
            elif key == "stackoverflow" and not re.match(
                r"^https?://(www\.)?stackoverflow\.com/.*$", link
            ):
                del professional_links[key]

    if candidate.get("educations") != []:
        educations = candidate["educations"]
        for education in educations:
            if (
                education.get("gpa_zscore") != None
                and education.get("gpa_zscore") != ""
            ):
                gpa_zscore = education["gpa_zscore"]
                try:
                    gpa_zscore = float(gpa_zscore)
                except ValueError:
                    education["gpa_zscore"] = None

            if (
                education.get("start_year") != None
                and education.get("start_year") != ""
            ):
                education["start_year"] = validate_year(education.get("start_year"))

            if education.get("end_year") != None and education.get("end_year") != "":
                education["end_year"] = validate_year(education.get("end_year"))

    if candidate.get("experiences") != []:
        experiences = candidate["experiences"]
        for experience in experiences:
            if (
                experience.get("start_year") != None
                and experience.get("start_year") != ""
            ):
                experience["start_year"] = validate_year(experience.get("start_year"))

            if experience.get("end_year") != None and experience.get("end_year") != "":
                experience["end_year"] = validate_year(experience.get("end_year"))

    if candidate.get("certifications") != []:
        certifications = candidate["certifications"]
        for certification in certifications:
            if certification.get("year") != None and certification.get("year") != "":
                certification["year"] = validate_year(certification.get("year"))

    if candidate.get("projects") != []:
        projects = candidate["projects"]
        for project in projects:
            if project.get("github") != None and project.get("github") != "":
                github = project["github"]
                if not re.match(r"^https?://(www\.)?github\.com/.*$", github):
                    project["github"] = ""

    return data
