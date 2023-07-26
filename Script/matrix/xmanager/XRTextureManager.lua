XRTextureManager = XRTextureManager or {}


local RTextureCache = nil


function XRTextureManager.SetTextureCache(rtImg)
    --if not RTextureCache then
    --    local screenWid = CS.XUiManager.RealScreenWidth
    --    local screenHei = CS.XUiManager.RealScreenHeight
    --    RTextureCache = CS.UnityEngine.RenderTexture(screenWid,screenHei,24)
    --    RTextureCache.antiAliasing = 2
    --end
    --XRTextureManager.SetCamerRT()
    --rtImg.texture = RTextureCache
    --rtImg.gameObject:SetActive(true)
    rtImg.gameObject:SetActive(false)
end

function XRTextureManager.ClearCamerRT()
    --local cameraRest = CS.XUiManager.UiModelCamera
    --cameraRest.targetTexture = nil
end

function XRTextureManager.SetCamerRT()
    --local cameraRest = CS.XUiManager.UiModelCamera
    --cameraRest.targetTexture = RTextureCache
end

function XRTextureManager.DeleteTextureCache()
    if not RTextureCache then return end
    RTextureCache = nil
end