
import pytest
from django.core.exceptions import ValidationError
from django.utils import timezone
from app.models import Movie

@pytest.mark.django_db
@pytest.fixture
def test_movie():
    movie = Movie.objects.create(
        title="Inception",
        director="Christopher Nolan",
        screenwriter="Christopher Nolan",
        cast="Leonardo DiCaprio, Joseph Gordon-Levitt",
        genre="Sci-Fi/Action",
        release_date=timezone.datetime(2010, 7, 16).date(),
        runtime=148,
        plot_summary="A thief who steals corporate secrets through dream-sharing technology.",
        rating=8.8,
        language="English",
        country="USA/UK",
        is_public=True
    )
    return movie

@pytest.mark.django_db
def test_movie_creation(test_movie):
    assert test_movie.title == "Inception"
    assert test_movie.director == "Christopher Nolan"
    assert test_movie.rating == 8.8
    assert test_movie.is_public is True

    assert str(test_movie) == "Inception (2010)"


def test_movie_rating_validation():

    with pytest.raises(ValidationError):
        movie = Movie(
            title="Test Movie",
            director="Test Director",
            cast="Test Cast",
            genre="Test",
            release_date=timezone.now().date(),
            runtime=120,
            plot_summary="Test Summary",
            rating=10.1
        )
        movie.full_clean()


    with pytest.raises(ValidationError):
        movie = Movie(
            title="Test Movie",
            director="Test Director",
            cast="Test Cast",
            genre="Test",
            release_date=timezone.now().date(),
            runtime=120,
            plot_summary="Test Summary",
            rating=-0.1
        )
        movie.full_clean()

@pytest.mark.django_db
def test_movie_optional_fields():
    movie = Movie.objects.create(
        title="Interstellar",
        director="Christopher Nolan",
        cast="Matthew McConaughey",
        genre="Sci-Fi",
        release_date=timezone.datetime(2014, 11, 7).date(),
        runtime=169,
        plot_summary="A team of explorers travel through a wormhole in space.",
        screenwriter=None,
        rating=8.6
    )
    assert movie.screenwriter is None
    assert Movie.objects.count() == 1
