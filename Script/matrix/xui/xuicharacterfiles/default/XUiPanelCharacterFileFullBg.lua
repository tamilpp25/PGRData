local XUiPanelCharacterFileFullBgBase = require('XUi/XUiCharacterFiles/Base/XUiPanelCharacterFileFullBgBase')
--- 档案-试玩主界面全屏UI的控制器基类
---@class XUiPanelCharacterFileFullBg: XUiPanelCharacterFileFullBgBase
local XUiPanelCharacterFileFullBg = XClass(XUiPanelCharacterFileFullBgBase, 'XUiPanelCharacterFileFullBg')

function XUiPanelCharacterFileFullBg:OnStart(cfg)
    self.ActivityCfg = cfg
    self:InitVideo()

    self._StartRun = true

    --- 不是每个角色的试玩界面都需要手动控制播放背景动画，通过引用来区分
    if self.Animation then
        self:PlayAnimationWithMask("AnimEnable2", function()
            self:PlayAnimation("Loop2",nil,nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        end)
    end
end

function XUiPanelCharacterFileFullBg:OnEnable()
    self.PanelSpine.gameObject:SetActiveEx(true)

    if self._StartRun then
        self._StartRun = nil
    else
        --- 不是每个角色的试玩界面都需要手动控制播放背景动画，通过引用来区分
        if self.Animation then
            self:PlayAnimation("Loop2",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        end
    end
end

function XUiPanelCharacterFileFullBg:OnDisable()
    self.PanelSpine.gameObject:SetActiveEx(false)
end

function XUiPanelCharacterFileFullBg:InitVideo()
    if self.VideoPlayer then
        local isPlayVideo = self.ActivityCfg.MovieId and self.ActivityCfg.MovieId ~= 0
        self.VideoPlayer.gameObject:SetActiveEx(isPlayVideo)
        if isPlayVideo then
            local config = XVideoConfig.GetMovieById(self.ActivityCfg.MovieId)
            self.VideoPlayer:SetVideoFromRelateUrl(config.VideoUrl)
            self.VideoPlayer:Play()
        end
    end
end

return XUiPanelCharacterFileFullBg