// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
// 
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/sql;
import ballerina/time;

public type Resume record {
    int id;
    @sql:Column {name: "full_name"}
    string full_name;
    @sql:Column {name: "email"}
    string email;
    @sql:Column {name: "phone"}
    string phone?;
    @sql:Column {name: "address"}
    string address?;
    @sql:Column {name: "country"}
    string country?;
    @sql:Column {name: "professional_links"}
    json professional_links?;
    @sql:Column {name: "skills"}
    json skills?;
    @sql:Column {name: "interests"}
    json interests?;
    @sql:Column {name: "languages"}
    json languages?;
    @sql:Column {name: "certifications"}
    json certifications?;
    @sql:Column {name: "educations"}
    json educations?;
    @sql:Column {name: "experiences"}
    json experiences?;
    @sql:Column {name: "projects"}
    json projects?;
    @sql:Column {name: "created_at"}
    time:Utc created_at?;
};

public type Project record {
    int id;
    @sql:Column {name: "projects"}
    json projects?;
};


    # Represents a candidate's complete profile
    public type Candidate record {|
        # Personal information of the candidate
        PersonalInfo personal_info;
        # Professional links of the candidate
        ProfessionalLinks professional_links;
        # Educational qualifications of the candidate
        Education[] educations;
        # Professional experiences of the candidate
        Experience[] experiences;
        # Skills possessed by the candidate
        string[] skills;
        # Certifications obtained by the candidate
        Certification[] certifications;
        # Projects completed or ongoing by the candidate
        Projects[] projects;
        # Languages known by the candidate
        Language[] languages;
        # Interests of the candidate
        string[] interests;
    |};

    # Personal information about a person
    public type PersonalInfo record {|
        # The full name of the candidate
        string full_name?;
        # The email address of the candidate
        string email?;
        # The contact number of the candidate
        string phone?;
        # The physical address of the candidate without the country
        string address?;
        # The country of residence of the candidate
        string country?;
    |};

    # Professional links of the candidate
    public type ProfessionalLinks record {|
        # The LinkedIn profile of the candidate
        string linkedin?;
        # The GitHub profile of the candidate
        string github?;
        # The portfolio website of the candidate
        string portfolio?;
        # The GitLab profile of the candidate
        string gitlab?;
        # The Bitbucket profile of the candidate
        string bitbucket?;
        # The HackerRank profile of the candidate
        string hackerrank?;
        # The LeetCode profile of the candidate
        string leetcode?;
        # The Stack Overflow profile of the candidate
        string stackoverflow?;
        # The Medium profile of the candidate
        string medium?;
        # The Dev.to profile of the candidate
        string devto?;
        string kaggle?;
    |};

    # Educational qualification of the candidate
    public type Education record {|
        # The degree obtained by the candidate
        string degree?;
        # The institution from which the degree or the exam was obtained
        string institution?;
        # The location of the institution
        string location?;
        # The GPA or Z-Score of the candidate of the degree or the exam
        float? gpa_zscore?;
        # The started year of the institution
        int? start_year?;
        # The end year of the institution
        int? end_year?;
    |};

    # Professional experience of the candidate
    public type Experience record {|
        # The job title held by the candidate
        string job_title?;
        # The company where the candidate worked
        string company?;
        # The location of the company
        string location?;
        # The start date of the job
        int? start_date?;
        # The end date of the job
        int? end_date?;
    |};

    # A certification obtained by the candidate
    public type Certification record {|
        # The name of the certification
        string name?;
        # The organization that issued the certification
        string issued_by?;
        # The year in which the certification was obtained
        int? year?;
        # The link to the certification
        string link?;
    |};

    # A project completed or ongoing by the candidate
    public type Projects record {|
        # The name of the project
        string name?;
        # A brief description of the project
        string description?;
        # Technologies used in the project
        string[] technologies?;
        # The link to the GitHub repository of the project
        string github?;
    |};

    # A language known by the candidate
    public type Language record {|
        # The language known by the candidate
        string language?;
        # The proficiency level of the language
        string proficiency?;
    |};