local XUiFightTutorial = XLuaUiManager.Register(XLuaUi, "UiFightTutorial")

local XUiFightTutorialDynamicTable = require("XUi/XUiFightTutorial/XUiFightTutorialDynamicTable")
local XUiFightTutorialDynamicGrid = require("XUi/XUiFightTutorial/XUiFightTutorialDynamicGrid")
local XUiFightTutorialTabGrid = require("XUi/XUiFightTutorial/XUiFightTutorialTabGrid")

function XUiFightTutorial:OnAwake()
    self.PanelNr.gameObject:SetActiveEx(false)
    self.BtnCloseDetail.CallBack = function() self:OnBtnBackClick() end
    self.PanelBtn1.CallBack = function() self:OnBtnLastClick() end
    self.PanelBtn2.CallBack = function() self:OnBtnNextClick() end
    self.UiFightTutorialDynamicTable = XUiFightTutorialDynamicTable.New(self, self.PanelTutorial, XUiFightTutorialDynamicGrid)
end

function XUiFightTutorial:OnStart()
    self:RegisterUIEvent();
end

function XUiFightTutorial:OnEnable(templateId)
    if CS.XFight.IsRunning then
        CS.XFight.Instance:Pause()
    end

    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)

    if not XTool.UObjIsNil(self.AnimEnable) then
        self.AnimEnable:Stop()
        self.AnimEnable:Play()
    end

    CS.XBlurHelper.GetBlurScreenCapture(CS.XRLManager.Camera.Camera,
        CS.XGraphicManager.RenderConst.Ui.PopupBackgroundBlurInfo, 
        function(tex2D)
            self.BlurTex = tex2D
            self.ImgBlur.texture = tex2D
        end, false)

    local configAgency = XMVCA:GetAgency(ModuleId.XUiFightTutorial)
    local config = configAgency:GetConfig(templateId)

    local content = {}
    local index = 1
    for k, v in pairs(config.Titles) do
        if config.Titles[k] then
            content[index] = {
                Title = config.Titles[k],
                Content = config.Contents[k],
                AssetType = config.AssetTypes[k],
                AssetPath = config.AssetPaths[k],
            }
            index = index + 1
        end
    end

    self.MaxIndex = #content

    self.TabGrid.gameObject:SetActiveEx(true)

    self.TabList = {}
    for i = 1, self.MaxIndex do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.TabGrid, self.Tab)
        self.TabList[i] = XUiFightTutorialTabGrid.New(obj)
    end

    self.TabGrid.gameObject:SetActiveEx(false)
    self.BtnCloseDetail.gameObject:SetActiveEx(false) -- 一开始隐藏关闭按钮

    self.CurrentIndex = 0;
    self.UiFightTutorialDynamicTable:RefreshList(content, self.CurrentIndex, true)
    
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_UI_TUTORIAL_OPEN)
end

function XUiFightTutorial:OnDisable()
    if self.TabList then
        for k, v in pairs(self.TabList) do
            v:Destroy()
        end
    end

    XDataCenter.InputManagerPc.ResumeCurInputMap()

    self.TabList = nil

    if CS.XFight.IsRunning then
        CS.XFight.Instance:Resume()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_UI_TUTORIAL_CLOSE)

    if self.BlurTex then
        CS.UnityEngine.Object.Destroy(self.BlurTex)
        self.BlurTex = nil
    end

    if not XTool.UObjIsNil(self.AnimEnable) then
        self.AnimEnable.time = 0
        self.AnimEnable:Evaluate()
        self.AnimEnable:Stop()
    end
end

------------------------------------------------------------------

function XUiFightTutorial:OnBtnBackClick()
    self.UiFightTutorialDynamicTable:StopAll()
    self:Close()
end

function XUiFightTutorial:OnBtnLastClick()
    local currIndex = self.UiFightTutorialDynamicTable:GetCurrentSelectedIndex()
    if currIndex > 0 then
        self.UiFightTutorialDynamicTable:StopAll()
        self.UiFightTutorialDynamicTable:TweenToIndex(currIndex - 1)
    end
end

function XUiFightTutorial:OnBtnNextClick()
    local currIndex = self.UiFightTutorialDynamicTable:GetCurrentSelectedIndex()
    if currIndex < self.MaxIndex then
        self.UiFightTutorialDynamicTable:StopAll()
        self.UiFightTutorialDynamicTable:TweenToIndex(currIndex + 1)
    end
end

function XUiFightTutorial:SwitchToIndex(index)
    self.CurrentIndex = index
    if self.TabList then
        for k, v in pairs(self.TabList) do
            v:SetState(k == (index + 1))
        end
    end

    local grid = self.UiFightTutorialDynamicTable:GetGridDic()[index]
    grid:SetIsSelected(true)

    self.PanelBtn1.gameObject:SetActiveEx(index ~= 0)
    self.PanelBtn2.gameObject:SetActiveEx(index ~= (self.MaxIndex - 1))

    -- 第一次到尾页的时候开启关闭按钮
    if index == (self.MaxIndex - 1) then
        self.BtnCloseDetail.gameObject:SetActiveEx(true)
    end
end

function XUiFightTutorial:RegisterUIEvent()

end

return XUiFightTutorial