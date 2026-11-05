from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel, Field
from sentence_transformers import SentenceTransformer

from typing import Optional
from math import radians, sin, cos, sqrt, atan2

app = FastAPI(
    title="JobLink AI Service",
    version="1.0.0",
)


MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"

print("Loading AI model...")
model = SentenceTransformer(MODEL_NAME)
print("AI model loaded.")


class CandidateMatchRequest(BaseModel):
    jobTitle: str
    jobDescription: str

    jobCategory: Optional[str] = None

    requiredSkills: list[str] = Field(
        default_factory=list
    )

    workerBio: Optional[str] = None

    workerSkills: list[str] = Field(
        default_factory=list
    )

    workerCategories: list[str] = Field(
        default_factory=list
    )

    experiences: list[str] = Field(
        default_factory=list
    )


class CandidateMatchResponse(BaseModel):
    matchingScore: float
    semanticScore: float
    skillScore: float
    categoryScore: float
    reasons: list[str]


def normalize(text: str) -> str:
    return text.strip().lower()


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model": MODEL_NAME,
    }


@app.post(
    "/candidate-match",
    response_model=CandidateMatchResponse,
)
def candidate_match(
    data: CandidateMatchRequest,
):
    job_text_parts = [
        data.jobTitle,
        data.jobDescription,
        data.jobCategory or "",
        " ".join(data.requiredSkills),
    ]

    worker_text_parts = [
        data.workerBio or "",
        " ".join(data.workerSkills),
        " ".join(data.workerCategories),
        " ".join(data.experiences),
    ]

    job_text = " ".join(
        item
        for item in job_text_parts
        if item
    )

    worker_text = " ".join(
        item
        for item in worker_text_parts
        if item
    )

    embeddings = model.encode(
        [
            job_text,
            worker_text,
        ],
        normalize_embeddings=True,
    )

    semantic_score = float(
        embeddings[0] @ embeddings[1]
    )

    semantic_score = max(
        0.0,
        min(
            1.0,
            semantic_score,
        ),
    )

    semantic_score *= 100

    required_skills = {
        normalize(skill)
        for skill in data.requiredSkills
    }

    worker_skills = {
        normalize(skill)
        for skill in data.workerSkills
    }

    matched_skills = (
        required_skills
        & worker_skills
    )

    if required_skills:
        skill_score = (
            len(matched_skills)
            / len(required_skills)
        ) * 100
    else:
        skill_score = 100.0

    category_score = 0.0

    if data.jobCategory:
        worker_categories = {
            normalize(category)
            for category
            in data.workerCategories
        }

        if normalize(
            data.jobCategory
        ) in worker_categories:
            category_score = 100.0

    # Phiên bản AI Matching V1
    matching_score = (
        semantic_score * 0.65
        + skill_score * 0.25
        + category_score * 0.10
    )

    matching_score = round(
        matching_score,
        2,
    )

    reasons: list[str] = []

    if required_skills:
        reasons.append(
            f"Khớp {len(matched_skills)}/"
            f"{len(required_skills)} kỹ năng yêu cầu."
        )

        if matched_skills:
            reasons.append(
                "Kỹ năng phù hợp: "
                + ", ".join(
                    sorted(matched_skills)
                )
            )
    else:
        reasons.append(
            "Tin tuyển dụng không yêu cầu kỹ năng cụ thể."
        )

    if category_score == 100:
        reasons.append(
            "Ngành nghề quan tâm của ứng viên "
            "phù hợp với công việc."
        )
    else:
        reasons.append(
            "Ngành nghề quan tâm chưa trùng trực tiếp "
            "với ngành của công việc."
        )

    if semantic_score >= 70:
        reasons.append(
            "Hồ sơ có mức tương đồng ngữ nghĩa cao "
            "với mô tả công việc."
        )
    elif semantic_score >= 45:
        reasons.append(
            "Hồ sơ có mức tương đồng ngữ nghĩa trung bình "
            "với mô tả công việc."
        )
    else:
        reasons.append(
            "Hồ sơ có mức tương đồng ngữ nghĩa thấp "
            "với mô tả công việc."
        )

    return CandidateMatchResponse(
        matchingScore=matching_score,

        semanticScore=round(
            semantic_score,
            2,
        ),

        skillScore=round(
            skill_score,
            2,
        ),

        categoryScore=round(
            category_score,
            2,
        ),

        reasons=reasons,
    )


# =========================================================
# JOB RECOMMENDATION MODELS
# =========================================================


class WorkerAvailability(BaseModel):
    dayOfWeek: str
    startTime: str
    endTime: str


class RecommendationJob(BaseModel):
    jobId: str

    title: str
    description: str

    category: str = ""

    skills: list[str] = Field(
        default_factory=list
    )

    # =====================================================
    # LOCATION
    # =====================================================

    latitude: Optional[float] = None
    longitude: Optional[float] = None

    # =====================================================
    # SALARY
    # =====================================================

    salary: Optional[float] = None
    salaryType: Optional[str] = None

    # =====================================================
    # SCHEDULE
    # =====================================================

    shiftType: Optional[str] = None

    startTime: Optional[str] = None
    endTime: Optional[str] = None

    workDays: list[str] = Field(
        default_factory=list
    )


class JobRecommendationRequest(BaseModel):
    # =====================================================
    # REQUIRED AI PROFILE DATA
    # =====================================================

    workerSkills: list[str] = Field(
        default_factory=list
    )

    workerCategories: list[str] = Field(
        default_factory=list
    )

    workerAvailabilities: list[
        WorkerAvailability
    ] = Field(
        default_factory=list
    )

    # =====================================================
    # EXTRA PROFILE DATA
    # =====================================================

    workerExperienceText: str = ""

    # =====================================================
    # OPTIONAL LOCATION BOOST
    # =====================================================

    workerLatitude: Optional[float] = None
    workerLongitude: Optional[float] = None

    # =====================================================
    # OPTIONAL SALARY BOOST
    # =====================================================

    workerPreferredMinSalary: Optional[
        float
    ] = None

    workerPreferredSalaryType: Optional[
        str
    ] = None

    # =====================================================
    # JOBS
    # =====================================================

    jobs: list[RecommendationJob]


# =========================================================
# DISTANCE
# =========================================================


def haversine_km(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
):
    earth_radius = 6371.0

    d_lat = radians(
        lat2 - lat1
    )

    d_lon = radians(
        lon2 - lon1
    )

    a = (
        sin(
            d_lat / 2
        ) ** 2
        + cos(
            radians(
                lat1
            )
        )
        * cos(
            radians(
                lat2
            )
        )
        * sin(
            d_lon / 2
        ) ** 2
    )

    c = (
        2
        * atan2(
            sqrt(
                a
            ),
            sqrt(
                1 - a
            ),
        )
    )

    return (
        earth_radius
        * c
    )


# =========================================================
# TIME HELPERS
# =========================================================


def time_to_minutes(
    value: Optional[str],
) -> Optional[int]:
    if not value:
        return None

    try:
        parts = (
            value
            .strip()
            .split(":")
        )

        if len(parts) < 2:
            return None

        hour = int(
            parts[0]
        )

        minute = int(
            parts[1]
        )

        if not (
            0 <= hour <= 23
            and
            0 <= minute <= 59
        ):
            return None

        return (
            hour * 60
            + minute
        )

    except (
        TypeError,
        ValueError,
    ):
        return None


def interval_segments(
    start: int,
    end: int,
) -> list[
    tuple[int, int]
]:
    # Ca bình thường:
    # 08:00 -> 17:00

    if end > start:
        return [
            (
                start,
                end,
            )
        ]

    # Nếu bằng nhau thì dữ liệu
    # không hợp lệ.
    if end == start:
        return []

    # Ca qua đêm:
    # 22:00 -> 06:00

    return [
        (
            start,
            1440,
        ),
        (
            0,
            end,
        ),
    ]


def overlap_minutes(
    start_a: int,
    end_a: int,
    start_b: int,
    end_b: int,
) -> int:
    segments_a = (
        interval_segments(
            start_a,
            end_a,
        )
    )

    segments_b = (
        interval_segments(
            start_b,
            end_b,
        )
    )

    total = 0

    for (
        a_start,
        a_end,
    ) in segments_a:
        for (
            b_start,
            b_end,
        ) in segments_b:
            start = max(
                a_start,
                b_start,
            )

            end = min(
                a_end,
                b_end,
            )

            if end > start:
                total += (
                    end - start
                )

    return total


def interval_duration(
    start: int,
    end: int,
) -> int:
    return sum(
        segment_end
        - segment_start
        for (
            segment_start,
            segment_end,
        ) in interval_segments(
            start,
            end,
        )
    )


# =========================================================
# AVAILABILITY SCORE
# =========================================================


def calculate_availability_score(
    worker_availabilities: list[
        WorkerAvailability
    ],
    job: RecommendationJob,
) -> Optional[float]:
    if (
        not worker_availabilities
        or
        not job.workDays
        or
        not job.startTime
        or
        not job.endTime
    ):
        # Không đủ dữ liệu để dùng signal này.
        # Không phạt điểm.
        return None

    job_start = (
        time_to_minutes(
            job.startTime
        )
    )

    job_end = (
        time_to_minutes(
            job.endTime
        )
    )

    if (
        job_start is None
        or
        job_end is None
    ):
        return None

    job_duration = (
        interval_duration(
            job_start,
            job_end,
        )
    )

    if job_duration <= 0:
        return None

    worker_by_day: dict[
        str,
        list[
            WorkerAvailability
        ],
    ] = {}

    for availability in (
        worker_availabilities
    ):
        day = (
            availability
            .dayOfWeek
            .strip()
            .upper()
        )

        if not day:
            continue

        worker_by_day.setdefault(
            day,
            [],
        ).append(
            availability
        )

    day_scores: list[
        float
    ] = []

    for raw_day in (
        job.workDays
    ):
        day = (
            raw_day
            .strip()
            .upper()
        )

        availabilities = (
            worker_by_day.get(
                day,
                [],
            )
        )

        best_score = 0.0

        for availability in (
            availabilities
        ):
            worker_start = (
                time_to_minutes(
                    availability.startTime
                )
            )

            worker_end = (
                time_to_minutes(
                    availability.endTime
                )
            )

            if (
                worker_start is None
                or
                worker_end is None
            ):
                continue

            overlap = (
                overlap_minutes(
                    job_start,
                    job_end,
                    worker_start,
                    worker_end,
                )
            )

            score = min(
                1.0,
                overlap
                / job_duration,
            )

            best_score = max(
                best_score,
                score,
            )

        day_scores.append(
            best_score
        )

    if not day_scores:
        return None

    return (
        sum(
            day_scores
        )
        / len(
            day_scores
        )
    )


# =========================================================
# SALARY SCORE
# =========================================================


def calculate_salary_score(
    request: JobRecommendationRequest,
    job: RecommendationJob,
) -> Optional[float]:
    preferred_salary = (
        request
        .workerPreferredMinSalary
    )

    preferred_type = (
        request
        .workerPreferredSalaryType
    )

    if (
        preferred_salary is None
        or
        preferred_type is None
        or
        job.salary is None
        or
        job.salaryType is None
    ):
        # Salary là optional.
        # Thiếu thì không phạt điểm.
        return None

    preferred_type_normalized = (
        preferred_type
        .strip()
        .upper()
    )

    job_type_normalized = (
        job.salaryType
        .strip()
        .upper()
    )

    # Không so sánh:
    # 50k/giờ với 8tr/tháng.
    if (
        preferred_type_normalized
        !=
        job_type_normalized
    ):
        return None

    if preferred_salary <= 0:
        return 1.0

    if job.salary >= (
        preferred_salary
    ):
        return 1.0

    return max(
        0.0,
        min(
            1.0,
            job.salary
            / preferred_salary,
        ),
    )


# =========================================================
# DISTANCE SCORE
# =========================================================


def calculate_distance_score(
    request: JobRecommendationRequest,
    job: RecommendationJob,
) -> tuple[
    Optional[float],
    Optional[float],
]:
    if (
        request.workerLatitude
        is None
        or
        request.workerLongitude
        is None
        or
        job.latitude
        is None
        or
        job.longitude
        is None
    ):
        # Location optional.
        # Không có thì không phạt.
        return (
            None,
            None,
        )

    distance = (
        haversine_km(
            request.workerLatitude,
            request.workerLongitude,
            job.latitude,
            job.longitude,
        )
    )

    if distance <= 5:
        score = 1.0

    elif distance <= 10:
        score = 0.85

    elif distance <= 20:
        score = 0.65

    elif distance <= 40:
        score = 0.40

    else:
        score = 0.20

    return (
        score,
        distance,
    )


# =========================================================
# JOB RECOMMENDATION
# =========================================================


@app.post(
    "/job-recommendations"
)
def job_recommendations(
    request:
        JobRecommendationRequest,
):
    # =====================================================
    # EMPTY JOB LIST
    # =====================================================

    if not request.jobs:
        return {
            "recommendations":
                []
        }

    # =====================================================
    # WORKER TEXT
    # =====================================================

    worker_text = " ".join(
        request.workerSkills
        +
        request.workerCategories
        +
        [
            request
            .workerExperienceText
        ]
    ).strip()

    if not worker_text:
        worker_text = (
            "part time worker"
        )

    # =====================================================
    # JOB TEXTS
    # =====================================================

    job_texts: list[
        str
    ] = []

    for job in (
        request.jobs
    ):
        job_text = " ".join(
            [
                job.title,
                job.description,
                job.category,
                " ".join(
                    job.skills
                ),
            ]
        ).strip()

        job_texts.append(
            job_text
        )

    # =====================================================
    # EMBEDDINGS
    # =====================================================

    worker_embedding = (
        model.encode(
            [
                worker_text
            ],
            normalize_embeddings=True,
        )[0]
    )

    job_embeddings = (
        model.encode(
            job_texts,
            normalize_embeddings=True,
        )
    )

    # =====================================================
    # NORMALIZED PROFILE DATA
    # =====================================================

    worker_skills = {
        skill
        .strip()
        .lower()

        for skill
        in request.workerSkills

        if skill.strip()
    }

    worker_categories = {
        category
        .strip()
        .lower()

        for category
        in request.workerCategories

        if category.strip()
    }

    recommendations = []

    # =====================================================
    # SCORE EACH JOB
    # =====================================================

    for (
        index,
        job,
    ) in enumerate(
        request.jobs
    ):
        # =================================================
        # 1. SEMANTIC SCORE
        # =================================================

        semantic_score = float(
            worker_embedding
            @
            job_embeddings[
                index
            ]
        )

        semantic_score = max(
            0.0,
            min(
                1.0,
                semantic_score,
            ),
        )

        # =================================================
        # 2. SKILL SCORE
        # =================================================

        required_skills = {
            skill
            .strip()
            .lower()

            for skill
            in job.skills

            if skill.strip()
        }

        if required_skills:
            matched_skills = (
                worker_skills
                &
                required_skills
            )

            skill_score = (
                len(
                    matched_skills
                )
                /
                len(
                    required_skills
                )
            )

        else:
            matched_skills = (
                set()
            )

            # Job không yêu cầu skill cụ thể
            # không nên bị điểm skill = 0.
            skill_score = 0.7

        # =================================================
        # 3. CATEGORY SCORE
        # =================================================

        category_name = (
            job.category
            .strip()
            .lower()
        )

        if (
            category_name
            and
            category_name
            in worker_categories
        ):
            category_score = (
                1.0
            )

        else:
            category_score = (
                0.0
            )

        # =================================================
        # 4. AVAILABILITY SCORE
        # =================================================

        availability_score = (
            calculate_availability_score(
                request
                .workerAvailabilities,
                job,
            )
        )

        # =================================================
        # 5. OPTIONAL DISTANCE SCORE
        # =================================================

        (
            distance_score,
            distance,
        ) = (
            calculate_distance_score(
                request,
                job,
            )
        )

        # =================================================
        # 6. OPTIONAL SALARY SCORE
        # =================================================

        salary_score = (
            calculate_salary_score(
                request,
                job,
            )
        )

        # =================================================
        # DYNAMIC WEIGHTS
        #
        # Core:
        # semantic      40%
        # skill         25%
        # category      15%
        # availability  20%
        #
        # Optional:
        # distance       8%
        # salary         7%
        #
        # Optional signal chỉ tham gia khi có dữ liệu.
        # Sau đó normalize theo tổng weight thực tế.
        #
        # Vì vậy thiếu location/salary KHÔNG bị trừ điểm.
        # =================================================

        weighted_sum = (
            semantic_score
            * 0.40
            +
            skill_score
            * 0.25
            +
            category_score
            * 0.15
        )

        total_weight = (
            0.40
            +
            0.25
            +
            0.15
        )

        if (
            availability_score
            is not None
        ):
            weighted_sum += (
                availability_score
                * 0.20
            )

            total_weight += (
                0.20
            )

        if (
            distance_score
            is not None
        ):
            weighted_sum += (
                distance_score
                * 0.08
            )

            total_weight += (
                0.08
            )

        if (
            salary_score
            is not None
        ):
            weighted_sum += (
                salary_score
                * 0.07
            )

            total_weight += (
                0.07
            )

        if total_weight <= 0:
            final_score = 0.0

        else:
            final_score = (
                weighted_sum
                /
                total_weight
            )

        final_score = max(
            0.0,
            min(
                1.0,
                final_score,
            ),
        )

        score = round(
            final_score
            * 100,
            2,
        )

        # =================================================
        # EXPLAINABLE REASONS
        # =================================================

        reasons: list[
            str
        ] = []

        # Semantic

        if (
            semantic_score
            >= 0.60
        ):
            reasons.append(
                "Nội dung công việc phù hợp với hồ sơ của bạn"
            )

        # Skills

        if matched_skills:
            reasons.append(
                "Kỹ năng phù hợp: "
                +
                ", ".join(
                    sorted(
                        matched_skills
                    )
                )
            )

        # Category

        if (
            category_score ==
            1.0
        ):
            reasons.append(
                "Công việc thuộc lĩnh vực bạn quan tâm"
            )

        # Availability

        if (
            availability_score
            is not None
        ):
            if (
                availability_score
                >= 0.80
            ):
                reasons.append(
                    "Lịch làm việc phù hợp tốt với thời gian rảnh của bạn"
                )

            elif (
                availability_score
                >= 0.40
            ):
                reasons.append(
                    "Lịch làm việc phù hợp một phần với thời gian rảnh của bạn"
                )

        # Distance

        if (
            distance
            is not None
            and
            distance <= 10
        ):
            reasons.append(
                f"Công việc cách vị trí của bạn khoảng {distance:.1f} km"
            )

        # Salary

        if (
            salary_score
            is not None
        ):
            if (
                salary_score
                >= 1.0
            ):
                reasons.append(
                    "Mức lương đáp ứng mức mong muốn của bạn"
                )

            elif (
                salary_score
                >= 0.80
            ):
                reasons.append(
                    "Mức lương gần với mức mong muốn của bạn"
                )

        # Fallback

        if not reasons:
            reasons.append(
                "Công việc có một số đặc điểm phù hợp với hồ sơ"
            )

        recommendations.append(
            {
                "jobId":
                    job.jobId,

                "score":
                    score,

                "reasons":
                    reasons,
            }
        )

    # =====================================================
    # SORT HIGH -> LOW
    # =====================================================

    recommendations.sort(
        key=lambda item:
            item[
                "score"
            ],
        reverse=True,
    )

    return {
        "recommendations":
            recommendations
    }