# movies/models.py
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator


class Movie(models.Model):
    """Core fields for Movie model (film metadata)"""
    # Core movie information
    title = models.CharField(max_length=255, verbose_name="Movie Title")
    director = models.CharField(max_length=200, verbose_name="Director")
    screenwriter = models.CharField(max_length=200, blank=True, null=True, verbose_name="Screenwriter")
    cast = models.TextField(verbose_name="Cast (comma-separated)")  # e.g., "Leonardo DiCaprio, Kate Winslet"
    genre = models.CharField(max_length=100, verbose_name="Genre (e.g., Drama/Action/Comedy)")
    release_date = models.DateField(verbose_name="Release Date")
    runtime = models.PositiveIntegerField(verbose_name="Runtime (minutes)")  # e.g., 120 mins

    # Extended metadata
    plot_summary = models.TextField(verbose_name="Plot Summary")
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=1,
        blank=True,
        null=True,
        verbose_name="IMDB Rating (0-10)",
        validators=[MinValueValidator(0), MaxValueValidator(10)]  # Enforce 0-10 range
    )
    language = models.CharField(max_length=50, default="English", verbose_name="Original Language")
    country = models.CharField(max_length=100, verbose_name="Country of Origin")
    is_public = models.BooleanField(default=True, verbose_name="Is Public")

    # Timestamps (auto-managed)
    created_at = models.DateTimeField(default=timezone.now, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        # Admin display configuration
        verbose_name = "Movie"
        verbose_name_plural = "Movie Management"
        # Default sort: newest releases first
        ordering = ["-release_date", "-created_at"]

    def __str__(self):
        # Human-readable display in admin list
        return f"{self.title} ({self.release_date.year})"