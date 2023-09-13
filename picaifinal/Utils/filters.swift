import Foundation
let sceneFilters: [String: [String: [String]]] = [
    "furniture": [
        "leftFilters": ["CISepiaTone", "CIPhotoEffectChrome", "CISRGBToneCurveToLinear", "CIEdges", "CIBoxBlur", "CIColorControls", "CIPhotoEffectInstant", "CIColorInvert", "CIPhotoEffectMono", "CIPhotoEffectProcess", "CIHighlightShadowAdjust"],
        "rightFilters": ["CIGaussianBlur", "CIPhotoEffectFade", "CIHighlightShadowAdjust", "CIColorControls", "CISepiaTone", "CISharpenLuminance", "CISRGBToneCurveToLinear", "CIVignetteEffect", "CIPhotoEffectTonal", "CIEdges", "CIUnsharpMask"]
    ],
    "person": [
        "leftFilters": ["CISRGBToneCurveToLinear", "CIGaussianBlur", "CIColorInvert", "CIEdges", "CIPhotoEffectFade", "CISharpenLuminance", "CIPhotoEffectMono", "CIColorPosterize", "CISepiaTone", "CIBoxBlur", "CIPhotoEffectChrome"],
        "rightFilters": ["CIColorControls", "CIHighlightShadowAdjust", "CIEdges", "CIPhotoEffectChrome", "CISRGBToneCurveToLinear", "CIPhotoEffectFade", "CIUnsharpMask", "CISepiaTone", "CIPhotoEffectInstant", "CISharpenLuminance", "CIBoxBlur"]
    ],
    "outdoors": [
        "leftFilters": ["CISharpenLuminance", "CIEdges", "CISRGBToneCurveToLinear", "CIPhotoEffectInstant", "CIHighlightShadowAdjust", "CIColorPosterize", "CIPhotoEffectChrome", "CIBoxBlur", "CIPhotoEffectFade", "CIPhotoEffectMono", "CIColorControls"],
        "rightFilters": ["CIColorInvert", "CIGaussianBlur", "CISharpenLuminance", "CISepiaTone", "CIPhotoEffectProcess", "CIColorPosterize", "CIBoxBlur", "CIEdges", "CISRGBToneCurveToLinear", "CIHighlightShadowAdjust", "CIPhotoEffectInstant"]
    ],
    "kitchen": [
            "leftFilters": ["CIColorControls", "CIPhotoEffectChrome", "CISepiaTone", "CISharpenLuminance", "CIPhotoEffectMono", "CIColorInvert", "CIEdges", "CIPhotoEffectProcess", "CIHighlightShadowAdjust", "CIGaussianBlur", "CISRGBToneCurveToLinear"],
            "rightFilters": ["CIPhotoEffectInstant", "CIColorControls", "CISepiaTone", "CIUnsharpMask", "CIColorInvert", "CISharpenLuminance", "CIPhotoEffectMono", "CIPhotoEffectFade", "CIEdges", "CIPhotoEffectChrome", "CIPhotoEffectTonal"]
        ],
        "office": [
            "leftFilters": ["CISharpenLuminance", "CIEdges", "CIColorControls", "CIPhotoEffectMono", "CIColorPosterize", "CIHighlightShadowAdjust", "CISepiaTone", "CISRGBToneCurveToLinear", "CIGaussianBlur", "CIPhotoEffectInstant", "CIPhotoEffectChrome"],
            "rightFilters": ["CIUnsharpMask", "CIPhotoEffectFade", "CIColorInvert", "CIPhotoEffectTonal", "CISepiaTone", "CIColorControls", "CISharpenLuminance", "CISRGBToneCurveToLinear", "CIPhotoEffectChrome", "CIEdges", "CIPhotoEffectMono"]
        ],
        "sports": [
            "leftFilters": ["CISepiaTone", "CIEdges", "CIPhotoEffectFade", "CIColorControls", "CIColorInvert", "CISRGBToneCurveToLinear", "CIGaussianBlur", "CIPhotoEffectMono", "CIUnsharpMask", "CIPhotoEffectTonal", "CISharpenLuminance"],
            "rightFilters": ["CIColorPosterize", "CIUnsharpMask", "CISharpenLuminance", "CISRGBToneCurveToLinear", "CIPhotoEffectChrome", "CIEdges", "CIColorInvert", "CIColorControls", "CIPhotoEffectMono", "CIPhotoEffectFade", "CIGaussianBlur"]
        ],
    "food": [
        "leftFilters": ["CIColorControls", "CIPhotoEffectChrome", "CISepiaTone", "CISharpenLuminance", "CIPhotoEffectFade", "CIColorPosterize", "CIPhotoEffectMono", "CIColorInvert", "CIEdges", "CIHighlightShadowAdjust", "CIGaussianBlur"],
        "rightFilters": ["CIColorInvert", "CISharpenLuminance", "CISepiaTone", "CIPhotoEffectMono", "CIColorControls", "CISRGBToneCurveToLinear", "CIEdges", "CIPhotoEffectChrome", "CIPhotoEffectInstant", "CIHighlightShadowAdjust", "CIPhotoEffectFade"]
    ],
    "living room": [
        "leftFilters": ["CIColorControls", "CIPhotoEffectFade", "CISharpenLuminance", "CISepiaTone", "CIPhotoEffectMono", "CIEdges", "CIColorInvert", "CIColorPosterize", "CIPhotoEffectChrome", "CISRGBToneCurveToLinear", "CIHighlightShadowAdjust"],
        "rightFilters": ["CISepiaTone", "CIColorInvert", "CISharpenLuminance", "CIPhotoEffectInstant", "CIColorControls", "CIColorPosterize", "CISRGBToneCurveToLinear", "CIEdges", "CIHighlightShadowAdjust", "CIGaussianBlur", "CIPhotoEffectTonal"]
    ],
    "bathroom": [
        "leftFilters": ["CIEdges", "CIColorControls", "CISharpenLuminance", "CIPhotoEffectFade", "CIPhotoEffectChrome", "CIColorPosterize", "CIHighlightShadowAdjust", "CISRGBToneCurveToLinear", "CIPhotoEffectMono", "CIGaussianBlur", "CISepiaTone"],
        "rightFilters": ["CIColorInvert", "CIPhotoEffectMono", "CIPhotoEffectChrome", "CISharpenLuminance", "CIColorControls", "CISepiaTone", "CIPhotoEffectInstant", "CIColorPosterize", "CISRGBToneCurveToLinear", "CIPhotoEffectFade", "CIEdges"]
    ],
    "bedroom": [
        "leftFilters": ["CIColorControls", "CIEdges", "CISharpenLuminance", "CIColorPosterize", "CISepiaTone", "CIColorInvert", "CISRGBToneCurveToLinear", "CIPhotoEffectMono", "CIPhotoEffectFade", "CIPhotoEffectInstant", "CIHighlightShadowAdjust"],
        "rightFilters": ["CIColorInvert", "CISepiaTone", "CIColorControls", "CISRGBToneCurveToLinear", "CIPhotoEffectChrome", "CIHighlightShadowAdjust", "CIGaussianBlur", "CISharpenLuminance", "CIPhotoEffectMono", "CIPhotoEffectFade", "CIEdges"]
    ],
    "clothing": [
        "leftFilters": ["CISharpenLuminance", "CIColorPosterize", "CIColorInvert", "CIPhotoEffectChrome", "CISepiaTone", "CIEdges", "CIColorControls", "CISRGBToneCurveToLinear", "CIGaussianBlur", "CIPhotoEffectInstant", "CIHighlightShadowAdjust"],
        "rightFilters": ["CIColorInvert", "CISepiaTone", "CIHighlightShadowAdjust", "CISharpenLuminance", "CIColorControls", "CISRGBToneCurveToLinear", "CIPhotoEffectMono", "CIEdges", "CIPhotoEffectFade", "CIPhotoEffectTonal", "CIColorPosterize"]
    ],
    "bookstore": [
        "leftFilters": ["CIColorControls", "CIHighlightShadowAdjust", "CISharpenLuminance", "CIColorInvert", "CISRGBToneCurveToLinear", "CIColorPosterize", "CIPhotoEffectMono", "CISepiaTone", "CIEdges", "CIGaussianBlur", "CIPhotoEffectChrome"],
        "rightFilters": ["CISharpenLuminance", "CISepiaTone", "CIColorControls", "CIPhotoEffectMono", "CIColorPosterize", "CISRGBToneCurveToLinear", "CIColorInvert", "CIEdges", "CIPhotoEffectChrome", "CIGaussianBlur", "CIPhotoEffectInstant"]
    ],
    "pets": [
        "leftFilters": ["CIPhotoEffectChrome", "CIColorControls", "CISharpenLuminance", "CISRGBToneCurveToLinear", "CIColorInvert", "CIColorPosterize", "CIEdges", "CIPhotoEffectMono", "CISepiaTone", "CIHighlightShadowAdjust", "CIGaussianBlur"],
        "rightFilters": ["CISepiaTone", "CIColorInvert", "CIHighlightShadowAdjust", "CISharpenLuminance", "CIColorControls", "CISRGBToneCurveToLinear", "CIColorPosterize", "CIEdges", "CIGaussianBlur", "CIPhotoEffectChrome", "CIPhotoEffectFade"]
    ],
    "electronics": [
        "leftFilters": ["CIColorControls", "CIPhotoEffectChrome", "CISepiaTone", "CISRGBToneCurveToLinear", "CIEdges", "CIColorInvert", "CISharpenLuminance", "CIHighlightShadowAdjust", "CIPhotoEffectMono", "CIColorPosterize", "CIPhotoEffectFade"],
        "rightFilters": ["CIColorInvert", "CISRGBToneCurveToLinear", "CISepiaTone", "CIEdges", "CIColorControls", "CISharpenLuminance", "CIPhotoEffectInstant", "CIColorPosterize", "CIPhotoEffectFade", "CIGaussianBlur", "CIPhotoEffectMono"]
    ],
    "household_items": [
            "leftFilters": ["CISharpenLuminance", "CIColorControls", "CIColorPosterize", "CISepiaTone", "CISRGBToneCurveToLinear", "CIEdges", "CIColorInvert", "CIPhotoEffectMono", "CIHighlightShadowAdjust", "CIPhotoEffectFade", "CIGaussianBlur"],
            "rightFilters": ["CIColorControls", "CIPhotoEffectMono", "CISharpenLuminance", "CIPhotoEffectInstant", "CISepiaTone", "CIColorPosterize", "CISRGBToneCurveToLinear", "CIPhotoEffectFade", "CIColorInvert", "CIGaussianBlur", "CIEdges"]
        ]
]
