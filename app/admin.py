# movies/admin.py
from django.contrib import admin
from .models import Movie  # Only import Movie model


@admin.register(Movie)
class MovieAdmin(admin.ModelAdmin):
    """Customize Movie model display/operations in Django Admin"""
    # 1. List view: Key fields to display (simplified for clarity)
    list_display = ["title", "director", "genre", "release_date", "runtime", "rating", "is_public"]

    # 2. Searchable fields (fast lookup for admins)
    search_fields = ["title", "director", "cast", "genre", "country"]

    # 3. Filter sidebar (quick filtering options)
    list_filter = [
        "genre",
        "language",
        "country",
        "is_public"
    ]

    # 4. Editable fields (update without opening detail view)
    list_editable = ["is_public", "rating"]

    # 5. Read-only fields (auto-generated timestamps)
    readonly_fields = ["created_at", "updated_at"]

    # 6. Detail view: Group fields for better UX (collapsible sections)
    fieldsets = (
        ("Core Movie Metadata", {
            "fields": ("title", "director", "screenwriter", "cast", "genre", "release_date", "runtime")
        }),
        ("Content & Rating", {
            "fields": ("plot_summary", "rating", "language", "country")
        }),
        ("Publishing Status", {
            "fields": ("is_public",)
        }),
        ("System Information", {
            "fields": ("created_at", "updated_at"),
            "classes": ("collapse",)  # Hidden by default (reduces clutter)
        }),
    )