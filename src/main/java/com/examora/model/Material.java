package com.examora.model;

import java.time.LocalDateTime;

/**
 * Material Model - Arsip Materi/Silabus
 */
public class Material {
    private Integer id;
    private Integer categoryId;
    private String categoryName;
    private String title;
    private String content;
    private String summary;
    private String filePath;
    private String fileType; // pdf, doc, docx, link, text, image
    private Long fileSize;
    private String targetTags;
    private Integer generatedById;
    private String generatedByName;
    private Boolean isGenerated;
    private Integer viewCount;
    private Integer downloadCount;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Material() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }

    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }

    public String getFileType() { return fileType; }
    public void setFileType(String fileType) { this.fileType = fileType; }

    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }

    public String getTargetTags() { return targetTags; }
    public void setTargetTags(String targetTags) { this.targetTags = targetTags; }

    public Integer getGeneratedById() { return generatedById; }
    public void setGeneratedById(Integer generatedById) { this.generatedById = generatedById; }

    public String getGeneratedByName() { return generatedByName; }
    public void setGeneratedByName(String generatedByName) { this.generatedByName = generatedByName; }

    public Boolean getIsGenerated() { return isGenerated; }
    public void setIsGenerated(Boolean isGenerated) { this.isGenerated = isGenerated; }

    public Integer getViewCount() { return viewCount; }
    public void setViewCount(Integer viewCount) { this.viewCount = viewCount; }

    public Integer getDownloadCount() { return downloadCount; }
    public void setDownloadCount(Integer downloadCount) { this.downloadCount = downloadCount; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // Helper method to check if material matches user's tag
    public boolean matchesTag(String userTag) {
        if (targetTags == null || targetTags.trim().isEmpty() || "ALL".equals(targetTags)) {
            return true;
        }
        if (userTag == null || userTag.trim().isEmpty()) {
            return false;
        }
        String[] tags = targetTags.split(",");
        for (String tag : tags) {
            if (tag.trim().equalsIgnoreCase(userTag.trim())) {
                return true;
            }
        }
        return false;
    }
}
