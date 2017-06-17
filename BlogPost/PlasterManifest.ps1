PlasterManifest {
 Metadata {
        Title = "Blog Post"
        TemplateName = 'BlogPost'
        Author = "David Christian"
        Description = "Creates a new blog post draft for OverPoweredShell.com"
        TemplateVersion = '0.0.1'
    }
    
    Parameters {
        text -Name PostTitle -Prompt "Title of your new post"
    }

    Content {
        TemplateFile -Source 'blogPost.md' -Destination '${PLASTER_PARAM_PostTitle}.md'
    }
} | Export-PlasterManifest -Destination .\PlasterManifest.xml -Verbose