---==============================
   ---@desc: UI，每个小人物包括：头，身体，腿
---==============================
local XUiPanelTeam = XClass(nil, "XUiPanelTeam")
--身体部位
local BodyType = {
    --头部
    Head = 1,
    --身体
    Body = 2,
    --腿
    Legs = 3
}
--滑动方向
local Direction = {
    --向左滑
    Left = 0,
    --向右滑
    Right = 1
}

function XUiPanelTeam:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
    
    --根据身体类型回调函数
    self.BodyType2Func = {
        [BodyType.Head] = handler(self, self.RefreshHeadLR),
        [BodyType.Body] = handler(self, self.RefreshBodyLR),
        [BodyType.Legs] = handler(self, self.RefreshLegsLR),
    }
end

---==============================
   ---@desc: 设置头部图片
   ---@param: {iconLeft} {iconRight} 头像Id
---==============================
function XUiPanelTeam:RefreshHeadLR(iconLeft, iconRight)
    self:SetImage(iconLeft, iconRight, self.RImgHeadL, self.RImgHeadR)

end

---==============================
   ---@desc: 设置身体图片
   ---@param: {iconLeft} {iconRight} 头像Id
---==============================
function XUiPanelTeam:RefreshBodyLR(iconLeft, iconRight)
    self:SetImage(iconLeft, iconRight, self.RImgBodyL, self.RImgBodyR)
end

---==============================
   ---@desc: 设置腿部图片
   ---@param: {iconLeft} {iconRight} 头像Id
---==============================
function XUiPanelTeam:RefreshLegsLR(iconLeft, iconRight)
    self:SetImage(iconLeft, iconRight, self.RImgLegL, self.RImgLegR)
end

function XUiPanelTeam:SetImage(iconLeft, iconRight, rawImageL, rawImageR)
    local iconL = XBodyCombineGameConfigs.GetSmallIcon(iconLeft)
    local iconR = XBodyCombineGameConfigs.GetSmallIcon(iconRight)
    if iconL then
        rawImageL:SetRawImage(iconL)
    end

    if iconR then
        rawImageR:SetRawImage(iconR)
    end
end

--===========================================================================
 ---@desc 接头霸王游戏界面
--===========================================================================
local XUiBodyCombineGamePlay = XLuaUiManager.Register(XLuaUi, "UiBodyCombineGamePlay")

--问题提示最大数
local Max_QuestionDesc_Members = 3
--拼图最大数
local Max_Team_Member = 3

function XUiBodyCombineGamePlay:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiBodyCombineGamePlay:OnStart(stage)
    ---@type-XBodyCombineStage
    self.Stage = stage

    local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ itemId }, self.PanelAsset)

    self.UiPanelTeam = {}
    --初始化各个部位显示
    for idx= 1, Max_Team_Member do
        local panel = XUiPanelTeam.New(self["PanelTeam"..idx])
        local hId, bId, lId = self.Stage:GetColData(idx)
        panel:RefreshHeadLR(hId, hId)
        panel:RefreshBodyLR(bId, bId)
        panel:RefreshLegsLR(lId, lId)
        self.UiPanelTeam[idx] = panel
    end
    --身体部位获取Stage内的数据    
    self.BodyType2StageType = {
        [BodyType.Head] = self.Stage:GetHead(),
        [BodyType.Body] = self.Stage:GetBody(),
        [BodyType.Legs] = self.Stage:GetLegs()
    }
    --身体部位 -> 动画名
    self.BodyDir2AnimaName = {
        [BodyType.Head] = {
            Back = "HeadBack",
            Flip = "HeadFlip",
        },
        [BodyType.Body] = {
            Back = "BodyBack",
            Flip = "BodyFlip",
        },
        [BodyType.Legs] = {
            Back = "LegBack",
            Flip = "LegFlip",
        },
    }
    
    local questionDesc = self.Stage:GetQuestionDesc()
    --问题描述
    for idx = 1, Max_QuestionDesc_Members do
        local desc = questionDesc[idx]
        local text = self["TxtMessage"..idx]
        local img = self["ImgTip"..idx]
        img.gameObject:SetActiveEx(desc and true or false)
        if not desc then
            text.gameObject:SetActiveEx(false)
        else
            text.gameObject:SetActiveEx(true)
            text.text = desc
        end
    end
    --关卡描述
    self.TxtDescription.text = self.Stage:GetDesc()
    --活动名
    self.RImgTittle:SetRawImage(XDataCenter.BodyCombineGameManager.GetActivityTitle())
    --问题附图
    local icon = self.Stage:GetSuspectIcon()
    if icon and icon ~= "" then
        self.RImgSuspects:SetRawImage(icon)
    end


end

function XUiBodyCombineGamePlay:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END, function()
        XDataCenter.BodyCombineGameManager.OnActivityEnd()
    end, self)
end

function XUiBodyCombineGamePlay:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END, function()
        XDataCenter.BodyCombineGameManager.OnActivityEnd()
    end, self)
end

function XUiBodyCombineGamePlay:InitUI()
    self.BtnHelp.gameObject:SetActiveEx(false)
    
end 

function XUiBodyCombineGamePlay:InitCB()
    
    self.BtnBack.CallBack = function() 
        self:Close()
    end

    self.BtnMainUi.CallBack = function ()
        XLuaUiManager.RunMain()
    end
    
    self.PanelBtnShangL.CallBack = function() 
        self:ChangePanel(BodyType.Head, Direction.Left)
    end

    self.PanelBtnZhongL.CallBack = function()
        self:ChangePanel(BodyType.Body, Direction.Left)
    end

    self.PanelBtnXiaL.CallBack = function()
        self:ChangePanel(BodyType.Legs, Direction.Left)
    end

    self.PanelBtnShangR.CallBack = function()
        self:ChangePanel(BodyType.Head, Direction.Right)
    end

    self.PanelBtnZhongR.CallBack = function()
        self:ChangePanel(BodyType.Body, Direction.Right)
    end

    self.PanelBtnXiaR.CallBack = function()
        self:ChangePanel(BodyType.Legs, Direction.Right)
    end
    
    self.BtnTcanchaungBlack.CallBack = function()
        self:OnBtnConfirmClick()
    end
end 

function XUiBodyCombineGamePlay:ChangePanel(bodyType, direction)
    local part = self.BodyType2StageType[bodyType]
    if not part then return end


    if direction == Direction.Left then
        self.Stage:PlayNext(part)
    elseif direction == Direction.Right then
        self.Stage:PlayLast(part)
    end


    local flipAnim = self.BodyDir2AnimaName[bodyType].Flip
    local backAnim = self.BodyDir2AnimaName[bodyType].Back

    local beginCb = function()
        local data = part:GetCurData()
        for idx = 1, Max_Team_Member do
            local panel = self.UiPanelTeam[idx]
            local func = panel.BodyType2Func[bodyType]
            func(data[idx], data[idx])
        end
        
        
    end
    
    local finishCb = function()
        self:PlayAnimationWithMask(backAnim, nil, beginCb)
    end
    self:PlayAnimationWithMask(flipAnim, finishCb)
    
end 

function XUiBodyCombineGamePlay:OnBtnConfirmClick()
    local correct = self.Stage:IsCorrect()
    if not correct then
        XUiManager.TipText("BodyCombineGameWrongAnswer")
        return
    end
    local data = self.Stage:GetCurData()
    local stageId = self.Stage:GetStageId()
    XDataCenter.BodyCombineGameManager.BodyCombineFinishRequest(stageId, data, handler(self, self.OnWin))
end 


function XUiBodyCombineGamePlay:OnWin()
    XLuaUiManager.Open("UiBodyCombineGameSuccess", self.Stage)
end