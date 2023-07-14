local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")
local XUiGuildDormPhotographData = require("XUi/XUiGuildDorm/Photograph/XUiGuildDormPhotographData")

-- 拍照面板
---@class XUiGuildDormPanelPhotograph : XSignalData
---@field CapturePanel XUiPhotographCapturePanel
---@field SDKPanel XUiPhotographSDKPanel
---@field PhotographData XUiGuildDormPhotographData
---@field Photo UnityEngine.RectTransform
local XUiGuildDormPanelPhotograph = XClass(XSignalData, "XUiGuildDormPanelPhotograph")

function XUiGuildDormPanelPhotograph:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.IsPhotographModel = false
end

function XUiGuildDormPanelPhotograph:OnStart()
    self.CapturePanel = XUiPhotographCapturePanel.New(self, self.PanelCapture)
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    self.PhotographData = XUiGuildDormPhotographData.New()

    self:SetProportionImage()
    -- 工会名称
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    -- 工会Id
    local guildId = XDataCenter.GuildManager.GetGuildId()
    self.TxtGuildID.text = string.format("ID: %08d", guildId)
    -- 玩家名称
    self.TxtPlayerName.text = XPlayer.Name
    -- 玩家等级
    self.TxtLevel.text = XPlayer.GetLevelOrHonorLevel()
    -- 玩家Id
    self.TxtPlayerID.text = string.format("ID: %s", XPlayer.Id)
end

function XUiGuildDormPanelPhotograph:OnEnable()
    self:UpdateView()
    self:SwitchPhotographModel()
end

function XUiGuildDormPanelPhotograph:OnDestroy()
    XDataCenter.PhotographManager.ClearTextureCache()
end

function XUiGuildDormPanelPhotograph:UpdateView()
    -- logo
    self:UpdateLogoView()
    -- 工会信息
    self:UpdateGuildView()
    -- 玩家信息
    self:UpdatePlayerView()
    -- 工会id
    self.TxtGuildID.transform.parent.gameObject:SetActiveEx(self.PhotographData:GetOpenGuildId())
    -- 玩家等级
    self.TxtPlayerLv.gameObject:SetActiveEx(self.PhotographData:GetOpenLevel())
    -- 玩家Uid
    self.TxtPlayerID.gameObject:SetActiveEx(self.PhotographData:GetOpenUId())
    -- 刷新位置
    self:UpdateLogoSiblingIndex()
    self:UpdateGuildSiblingIndex()
    self:UpdatePlayerSiblingIndex()
end

function XUiGuildDormPanelPhotograph:UpdateLogoView()
    local alignment = self.PhotographData:GetLogoAlignment()
    local show = alignment.Value ~= 0
    self.ImgLogo.gameObject:SetActiveEx(show)
    if show then
        self:SetLogoOrInfoPos(self.ImgLogo.transform, alignment)
    end
end

function XUiGuildDormPanelPhotograph:UpdateGuildView()
    local alignment = self.PhotographData:GetGuildAlignment()
    local show = alignment.Value ~= 0
    self.PanelGuild.gameObject:SetActiveEx(show)
    if show then
        self:SetLogoOrInfoPos(self.PanelGuild.transform, alignment, self.PanelGuild)
    end
end

function XUiGuildDormPanelPhotograph:UpdatePlayerView()
    local alignment = self.PhotographData:GetPlayerAlignment()
    local show = alignment.Value ~= 0
    self.PanelPlayer.gameObject:SetActiveEx(show)
    if show then
        self.TxtPlayerLv.ChildAlignment = alignment.Anchor.x >= 0.5 and CS.UnityEngine.TextAnchor.UpperRight or CS.UnityEngine.TextAnchor.UpperLeft
        self:SetLogoOrInfoPos(self.PanelPlayer.transform, alignment, self.PanelPlayer)
    end
end

function XUiGuildDormPanelPhotograph:UpdateLogoSiblingIndex()
    local alignment = self.PhotographData:GetLogoAlignment()
    local show = alignment.Value ~= 0
    if show then
        local siblingIndex = alignment.Value <= 2 and 0 or 2
        self.ImgLogo.transform:SetSiblingIndex(siblingIndex)
    end
end

function XUiGuildDormPanelPhotograph:UpdateGuildSiblingIndex()
    local alignment = self.PhotographData:GetGuildAlignment()
    local show = alignment.Value ~= 0
    if show then
        self.PanelGuild.transform:SetSiblingIndex(1)
    end
end

function XUiGuildDormPanelPhotograph:UpdatePlayerSiblingIndex()
    local alignment = self.PhotographData:GetPlayerAlignment()
    local show = alignment.Value ~= 0
    if show then
        local siblingIndex = alignment.Value <= 2 and 2 or 0
        self.PanelPlayer.transform:SetSiblingIndex(siblingIndex)
    end
end

---@param rectTransform UnityEngine.Transform
function XUiGuildDormPanelPhotograph:SetLogoOrInfoPos(rectTransform, alignment, autoLayout)
    if not rectTransform or not alignment then
        return
    end
    local anchor = alignment.Anchor
    rectTransform.anchorMin = anchor
    rectTransform.anchorMax = anchor
    rectTransform.pivot = anchor
    rectTransform:SetParent(self[alignment.Node], false)
    if autoLayout then
        autoLayout.ChildAlignment = anchor.x >= 0.5 and CS.UnityEngine.TextAnchor.MiddleRight or CS.UnityEngine.TextAnchor.MiddleLeft
    end
end

function XUiGuildDormPanelPhotograph:Photograph()
    XCameraHelper.ScreenShotNew(self.ImgPicture, CS.XUiManager.Instance.UiCamera, function(screenShot)
        -- 截图后操作
        XCameraHelper.ScreenShotNew(self.CapturePanel.ImagePhoto, self.CameraCupture, function(shot) -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
            self.ShareTexture = shot
            self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
            self.Photo:PlayTimelineAnimation(function()
                if not XTool.UObjIsNil(self.ImgPicture.mainTexture) and self.ImgPicture.mainTexture.name ~= "UnityWhite" then -- 销毁texture2d (UnityWhite为默认的texture2d)
                    CS.UnityEngine.Object.Destroy(self.ImgPicture.mainTexture)
                end
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(true)
            end, function()
                self:ChangeState(XPhotographConfigs.PhotographViewState.SDK)
                self.CapturePanel.BtnClose.gameObject:SetActiveEx(false)
            end)
        end, function() CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture) end)
    end)
    XDataCenter.PhotographManager.SendPhotoGraphRequest()
end

function XUiGuildDormPanelPhotograph:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.CapturePanel:Hide()
        self.SDKPanel:Hide()
        self:PhotographUiEnable(true)
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.CapturePanel:Show()
        self.SDKPanel:Hide()
    elseif state == XPhotographConfigs.PhotographViewState.SDK then
        self.CapturePanel:Show()
        self.SDKPanel:Show()
    end
end

function XUiGuildDormPanelPhotograph:PhotographUiEnable(value)
    self:EmitSignal("PhotographUiEnable",value)
    self.BtnSet.gameObject:SetActiveEx(value)
    self.BtnPhotograph.gameObject:SetActiveEx(value)
end

-- 设置拍照图片大小
function XUiGuildDormPanelPhotograph:SetProportionImage()
    local width, height = CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height
    local defaultSize = self.ImageContainer.sizeDelta
    local ratio = width / height
    local screenW = ratio * defaultSize.y
    self.ImageContainer.sizeDelta = Vector2(screenW, defaultSize.y)
    self.ImgPicture.rectTransform.sizeDelta = Vector2(CsXUiManager.RealScreenWidth, CsXUiManager.RealScreenHeight)
end

--region 按钮相关

function XUiGuildDormPanelPhotograph:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSet, self.OnBtnSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPhotograph, self.OnBtnPhotographClick)
end

function XUiGuildDormPanelPhotograph:OnBtnSetClick()
    XLuaUiManager.Open("UiGuildDormPhotoSet", self.PhotographData, function()
        self:UpdateView()
    end)
end

function XUiGuildDormPanelPhotograph:OnBtnPhotographClick()
    self:PhotographUiEnable(false)
    self:Photograph()
end

--endregion

--region 拍照模式相关

function XUiGuildDormPanelPhotograph:OnClick()
    self.IsPhotographModel = not self.IsPhotographModel
    self:SwitchPhotographModel()
end

function XUiGuildDormPanelPhotograph:SwitchPhotographModel()
    self:EmitSignal("OnSwitchPhotographModel", self.IsPhotographModel)
end

function XUiGuildDormPanelPhotograph:QuitPhotographModel()
    self.IsPhotographModel = false
    self:SwitchPhotographModel()
end

function XUiGuildDormPanelPhotograph:CheckPhotographModel()
    return self.IsPhotographModel
end
    
--endregion

return XUiGuildDormPanelPhotograph