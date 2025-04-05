from kor.nodes import Object, Text, Number

personal_info_schema = Object(
    id="personal_info",
    description="Personal information about a person.",
    attributes=[
        Text(
            id="full_name",
            description="The full name of the candidate.",
        ),
        Text(
            id="email",
            description="The email address of the candidate.",
        ),
        Text(
            id="phone",
            description="The contact number of the candidate.",
        ),
        Text(
            id="address",
            description="The physical address of the candidate without the country.",
        ),
        Text(
            id="country",
            description="The country of residence of the candidate.",
        ),
    ],
    examples=[
        (
            ("ASHLEY GILL 3 Lappage Court Telephone: 01882 652349 Tyler Green, Bucks. Mobile: 07717 121824 HP8 4JD "
            "Email: ashleygill2023@gotmail.com"),
            [
                {
                    "full_name": "Ashley Gill",
                    "email": "ashleygill2023@gotmail.com",
                    "phone": "01882 652349",
                    "address": "3 Lappage Court Tyler Green, Bucks.",
                    "country": "",
                }
            ],
        ),
        (
            ("Hasanga University of Moratuwa, Sri Lanka 2021 - Present Ranasinghe B.Sc. Engineering (Hons) Specialised "
            "in Computer Science and Engineering Computer Science & Stream: Data Science and Engineering Combined "
            "Mathematics(A), Physics(A), Chemistry(A) +94 70 168 4781 Z-Score: 2.0883 G.C.E Ordinary Level Examination "
            "(2017) hasanga-ranasinghe 8 A’s hasanga1 dinithhasangare@gmail.com Projects Kadawatha, Sri Lanka."),
            [
                {
                    "full_name": "Hasanga Ranasinghe",
                    "email": "dinithhasangare@gmail.com",
                    "phone": "+94 70 168 4781",
                    "address": "Kadawatha",
                    "country": "Sri Lanka",
                }
            ],
        ),
    ],
)

professional_links_schema = Object(
    id="professional_links",
    description="List of professional links of the candidate.",
    attributes=[
        Text(
            id="linkedin",
            description="The LinkedIn profile of the candidate.",
        ),
        Text(
            id="github",
            description="The GitHub profile of the candidate.",
        ),
        Text(
            id="portfolio",
            description="The portfolio website of the candidate.",
        ),
        Text(
            id="gitlab",
            description="The GitLab profile of the candidate.",
        ),
        Text(
            id="bitbucket",
            description="The Bitbucket profile of the candidate.",
        ),
        Text(
            id="hackerrank",
            description="The HackerRank profile of the candidate.",
        ),
        Text(
            id="leetcode",
            description="The LeetCode profile of the candidate.",
        ),
        Text(
            id="stackoverflow",
            description="The Stack Overflow profile of the candidate.",
        ),
        Text(
            id="medium",
            description="The Medium profile of the candidate.",
        ),
        Text(
            id="devto",
            description="The Dev.to profile of the candidate.",
        ),
    ],
    examples=[
        (
            ("LinkedIn: https://www.linkedin.com/in/johndoe GitHub: https://github.com/johndoe Portfolio: "
            "https://johndoe.com"),
            [
                {
                    "linkedin": "https://www.linkedin.com/in/johndoe",
                    "github": "https://github.com/johndoe",
                    "portfolio": "https://johndoe.com",
                    "gitlab": "",
                    "bitbucket": "",
                    "hackerrank": "",
                    "leetcode": "",
                    "stackoverflow": "",
                    "medium": "",
                    "devto": "",
                }
            ],
        ),
        (
            ("LinkedIn: https://www.linkedin.com/in/janedoe GitHub: https://github.com/janedoe GitLab: "
            "https://gitlab.com/janedoe"),
            [
                {
                    "linkedin": "https://www.linkedin.com/in/janedoe",
                    "github": "https://github.com/janedoe",
                    "portfolio": "",
                    "gitlab": "https://gitlab.com/janedoe",
                    "bitbucket": "",
                    "hackerrank": "",
                    "leetcode": "",
                    "stackoverflow": "",
                    "medium": "",
                    "devto": "",
                }
            ],
        ),
    ],
)

education_schema = Object(
    id="educations",
    description="List of educational qualifications of the candidate like degrees, a-level, o-level, school, etc.",
    attributes=[
        Text(
            id="degree",
            description="The degree obtained by the candidate.",
        ),
        Text(
            id="institution",
            description="The institution from which the degree or the exam was obtained.",
        ),
        Text(
            id="location",
            description="The location of the institution.",
        ),
        Number(
            id="gpa_zscore",
            description="The GPA or Z-Score of the candidate of the degree or the exam.",
        ),
        Number(
            id="start_year",
            description="The started year of the institution. Extract the year from the text. If the year is not \
                available, leave it empty.",
        ),
        Number(
            id="end_year",
            description="The end year of the institution. Extract the year from the text. If the year is not \
                available, leave it empty.",
        ),
    ],
    examples=[
        (
            "B.Sc. in Computer Science and Engineering (University of Moratuwa, Sri Lanka, 2021 - Present): \
                Specialized in Data Science and Engineering. GPA: 3.8/4.0. A-Level (Royal College, Colombo, \
                    Sri Lanka, 2019 - 2020): Combined Mathematics(A), Physics(A), Chemistry(A). Z-Score: 2.0883. \
                        O-Level (Royal College, Colombo, Sri Lanka, 2017): 8 A’s.",
            [
                {
                    "degree": "B.Sc. in Computer Science and Engineering",
                    "institution": "University of Moratuwa",
                    "location": "Sri Lanka",
                    "gpa_zscore": 3.8,
                    "start_year": 2021,
                    "end_year": None,
                },
                {
                    "degree": "A-Level",
                    "institution": "Royal College",
                    "location": "Colombo, Sri Lanka",
                    "gpa_zscore": 2.0883,
                    "start_year": 2019,
                    "end_year": 2020,
                },
                {
                    "degree": "O-Level",
                    "institution": "Royal College",
                    "location": "Colombo, Sri Lanka",
                    "gpa_zscore": None,
                    "start_year": 2017,
                    "end_year": None,
                },
            ],
        )
    ],
)

experience_schema = Object(
    id="experiences",
    description="List of professional experience of the candidate.",
    attributes=[
        Text(
            id="job_title",
            description="The job title held by the candidate.",
        ),
        Text(
            id="company",
            description="The company where the candidate worked.",
        ),
        Text(
            id="location",
            description="The location of the company.",
        ),
        Number(
            id="start_date",
            description="The start date of the job. Extract the year from the text. If the year is not available, \
                leave it empty.",
        ),
        Number(
            id="end_date",
            description="The end date of the job. Extract the year from the text. If the year is not available, \
            leave it empty.",
        ),
    ],
    examples=[
        (
            "Software Engineer at ABC Corp, San Francisco, CA (June 2018 - Present): Developed and maintained web \
            applications using Python and JavaScript. Led a team of 5 engineers to deliver projects on time.",
            [
                {
                    "job_title": "Software Engineer",
                    "company": "ABC Corp",
                    "location": "San Francisco, CA",
                    "start_date": 2018,
                    "end_date": None,
                }
            ],
        ),
        (
            "Data Analyst at XYZ Ltd, New York, NY (January 2016 - May 2018): Analyzed large datasets to provide \
                insights for business decisions. Created dashboards and reports using SQL and Tableau.",
            [
                {
                    "job_title": "Data Analyst",
                    "company": "XYZ Ltd",
                    "location": "New York, NY",
                    "start_date": 2016,
                    "end_date": 2018,
                }
            ],
        ),
    ],
)

skills_schema = Object(
    id="skills",
    description="List of skills possessed by the candidate. Extract all skills one by one, don't seperate them with \
        commas. Don't add communication languages like English, French, etc.",
    attributes=[
        Text(
            id="skill",
            description="A skill possessed by the candidate.",
        ),
    ],
    examples=[
        (
            "Programming Languages: Python, Java, C++ Web Development: HTML, CSS, JavaScript, Soft Skills: Effective \
                Communication, Team Work, Self Confidence, Time Management.",
            [
                {"skill": "Python"},
                {"skill": "Java"},
                {"skill": "C++"},
                {"skill": "HTML"},
                {"skill": "CSS"},
                {"skill": "Effective Communication"},
                {"skill": "Team Work"},
                {"skill": "Self Confidence"},
                {"skill": "Time Management"},
            ],
        )
    ],
)

certification_schema = Object(
    id="certifications",
    description="Certifications obtained by the candidate.",
    attributes=[
        Text(
            id="name",
            description="The name of the certification.",
        ),
        Text(
            id="issued_by",
            description="The organization that issued the certification.",
        ),
        Number(
            id="year",
            description="The year in which the certification was obtained.",
        ),
        Text(
            id="link",
            description="The link to the certification.",
        ),
    ],
    examples=[
        (
            "AWS Certified Solutions Architect - Associate (Amazon Web Services, 2020): \
                https://aws.amazon.com/certification/. Google Analytics Individual Qualification (Google, 2019): \
                    https://analytics.google.com/analytics/academy/",
            [
                {
                    "name": "AWS Certified Solutions Architect - Associate",
                    "issued_by": "Amazon Web Services",
                    "year": 2020,
                    "link": "https://aws.amazon.com/certification/",
                },
                {
                    "name": "Google Analytics Individual Qualification",
                    "issued_by": "Google",
                    "year": 2019,
                    "link": "https://analytics.google.com/analytics/academy/",
                },
            ],
        ),
        (
            "Google Analytics Individual Qualification",
            [
                {
                    "name": "Google Analytics Individual Qualification",
                    "issued_by": "",
                    "year": None,
                    "link": "",
                }
            ],
        ),
    ],
)

technologies_schema = Object(
    id="technologies",
    description="List of technologies known by the candidate.",
    attributes=[
        Text(
            id="technology",
            description="A technology known by the candidate.",
        )
    ],
    examples=[
        (
            "Python, Java, C++",
            [{"technology": "Python"}, {"technology": "Java"}, {"technology": "C++"}],
        )
    ],
)

project_schema = Object(
    id="projects",
    description="List of all the projects completed or ongoing by the candidate.",
    attributes=[
        Text(
            id="name",
            description="The name of the project.",
        ),
        Text(
            id="description",
            description="A brief description of the project. Don't summerize the project, extract the full description.",
        ),
        technologies_schema,
        Text(
            id="github",
            description="The link to the GitHub repository of the project.",
        ),
    ],
    examples=[
        (
            "AI Chatbot (Python, TensorFlow, Flask): An AI-powered chatbot for customer service. GitHub: www.github.com\
                /johndoe/chatbot. \nCustomer Churn Prediction (Python, Scikit-Learn, Tableau): Predicting customer \
                    churn using machine learning. GitHub: www.github.com/janedoe/churn-prediction",
            [
                {
                    "name": "AI Chatbot",
                    "description": "An AI-powered chatbot for customer service.",
                    "technologies": {
                        "technology": "Python",
                        "technology": "TensorFlow",
                        "technology": "Flask",
                    },
                    "github": "www.github.com/johndoe/chatbot",
                },
                {
                    "name": "Customer Churn Prediction",
                    "description": "Predicting customer churn using machine learning.",
                    "technologies": {
                        "technology": "Python",
                        "technology": "Scikit-Learn",
                        "technology": "Tableau",
                    },
                    "github": "www.github.com/janedoe/churn-prediction",
                },
            ],
        )
    ],
)

language_schema = Object(
    id="languages",
    description="List of languages known by the candidate. if the proficiency level is not available, leave it empty.",
    attributes=[
        Text(
            id="language",
            description="The language known by the candidate.",
        ),
        Text(
            id="proficiency",
            description="The proficiency level of the language.",
        ),
    ],
    examples=[
        (
            "English (Fluent), French (Intermediate), Spanish",
            [
                {"language": "English", "proficiency": "Fluent"},
                {"language": "French", "proficiency": "Intermediate"},
                {"language": "Spanish", "proficiency": ""},
            ],
        )
    ],
)

interests_schema = Object(
    id="interests",
    description="List of interests of the candidate.",
    attributes=[
        Text(
            id="interest",
            description="An interest of the candidate.",
        )
    ],
    examples=[
        (
            "Reading, Traveling, Cooking, Photography",
            [
                {"interest": "Reading"},
                {"interest": "Traveling"},
                {"interest": "Cooking"},
                {"interest": "Photography"},
            ],
        )
    ],
)

candidate_schema = Object(
    id="candidate",
    description="Extracted structured information about a candidate. Make sure to add all the attributes. If an \
    attribute is not available, leave it empty.",
    attributes=[
        personal_info_schema,
        professional_links_schema,
        education_schema,
        experience_schema,
        skills_schema,
        certification_schema,
        project_schema,
        language_schema,
        interests_schema,
    ],
)
