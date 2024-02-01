--周年回顾列表元素逻辑代理
local XUiGridAnniversaryReview=XClass(XUiNode,'XUiGridAnniversaryReview')
local XUiGridAnniversaryReviewData=require('XUi/XUiAnniversary/XUiGridAnniversaryReviewData')

function XUiGridAnniversaryReview:OnStart()
    self.Id=-1
    --初始化数据显示UI
    self.RectTrans=self.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self.DataUICtrl={}
    for i=0,100 do
        if self['PanelUI'..i] then
            self.DataUICtrl['PanelUI'..i]=XUiGridAnniversaryReviewData.New(self['PanelUI'..i],self)
        end
    end
    self.CenterPoints={}
    XTool.InitUiObjectByUi(self.CenterPoints,self.centerPoints)
    self.firstLoad=true
end

function XUiGridAnniversaryReview:Refresh(index)
    
    --获取配置：动态列表是从1开始的，配置表id是从0开始的，因此要-1
    self.Id=index-1
    local cfg=self._Control:GetReviewPictures()[index-1]
    --设置显示的图片
    self.ImgReview:SetRawImage(cfg.Address)

    --设置显示的UI
    for i, v in pairs(self.DataUICtrl) do
        v:Close()
    end
    for i, v in pairs(cfg.DisplayShowUI) do
        local uicfg=self._Control:GetAnniversaryReviewDataUIById(v)
        
        if uicfg and self[uicfg.UiName] then
            if self.Parent.alreadyLoadIndexes[index] == nil then
                self.CurUiCtrlAnimationFunc = function()
                    self.DataUICtrl[uicfg.UiName]:Open()
                    self.DataUICtrl[uicfg.UiName]:Refresh(uicfg.DataType,true)
                end
            else
                self.DataUICtrl[uicfg.UiName]:Open()
                self.DataUICtrl[uicfg.UiName]:Refresh(uicfg.DataType)
            end
        end
    end


    if self.firstLoad then--第一次加载时grid的尺寸需要下一帧才会更新，因此延时计算前驱后继
        self.firstLoad=false
        XScheduleManager.ScheduleNextFrame(function() self:InitPrePointAndNextPoint() end)
    else--之后都是立即执行，防止没来得及计算前驱后继，修正时使用之前的数据导致中心点计算错误
        self:InitPrePointAndNextPoint()
    end
end

function XUiGridAnniversaryReview:RefreshWithAnimation(index)
    if self.Id == index-1 and self.Parent.alreadyLoadIndexes[index] == nil and self.CurUiCtrlAnimationFunc then
        self.Parent.alreadyLoadIndexes[index] = true
        self.CurUiCtrlAnimationFunc()
        self.CurUiCtrlAnimationFunc = nil
    end
end

function XUiGridAnniversaryReview:GetAnchoredCenterPoint()
    if self.Id == -1 then return false,0,-1 end
    local cfg=self._Control:GetReviewPictures()[self.Id]
    local point=self.CenterPoints[cfg.FocusPointUi]
    if point then
        return true,self.RectTrans.localPosition+point.localPosition.y*Vector3.up+point.parent.localPosition.y*Vector3.up,self.Id+1
    else
        return false,0,self.Id+1
    end
end

function XUiGridAnniversaryReview:GetPreAnchoredCenterPoint()
    local index = self.preUIId == nil and -1 or self.preUIId+1
    if self.prePointLocalPosition then
        return true,self.RectTrans.localPosition+self.prePointLocalPosition.y*Vector3.up+self.prePoint.parent.localPosition.y*Vector3.up,index
    end
    return false,0,index
end

function XUiGridAnniversaryReview:GetNextAnchoredCenterPoint()
    local index = self.nextUIId == nil and -1 or self.nextUIId+1
    if self.nextPointLocalPosition then
        return true,self.RectTrans.localPosition+self.nextPointLocalPosition.y*Vector3.up+self.nextPoint.parent.localPosition.y*Vector3.up,index
    end
    return false,0,index
end

function XUiGridAnniversaryReview:GetAllAnchoredPoints()
    local result={}
    
    local _hasValue,_pos,_index = self:GetAnchoredCenterPoint()
    table.insert(result,{hasResult=_hasValue,result=_pos,index = _index})
    
    _hasValue,_pos,_index = self:GetPreAnchoredCenterPoint()
    table.insert(result,{hasResult=_hasValue,result=_pos,index = _index})
    
    _hasValue,_pos,_index = self:GetNextAnchoredCenterPoint()
    table.insert(result,{hasResult=_hasValue,result=_pos,index = _index})
    return result
end

--通过计算的方式直接得出前驱后继的居中点，这样可以进一步降低动态列表反复利用特性造成的短板，能够将更多的居中点纳入判定中
function XUiGridAnniversaryReview:InitPrePointAndNextPoint()
    self.preUIId = nil
    self.prePointLocalPosition=nil
    self.prePoint=nil

    self.nextUIId = nil
    self.nextPoint=nil
    self.nextPointLocalPosition=nil
    --向前找到一个居中点为止
    for i = 1, 10 do
        local preCfg=self._Control:GetReviewPictures()[self.Id-i]
        if preCfg then
            local prePoint=self.CenterPoints[preCfg.FocusPointUi]
            if prePoint then
                self.prePoint=prePoint
                self.prePointLocalPosition=Vector3(0,self.RectTrans.rect.height*i,0)+prePoint.localPosition
                if self.prePointAvatar==nil then
                    self.prePointAvatar=CS.UnityEngine.GameObject('prePoint')
                    self.prePointAvatar.transform:SetParent(self.prePoint.parent)
                end
                self.preUIId = preCfg.Id
                self.prePointAvatar.name='prePoint'
                self.prePointAvatar.transform.localPosition=self.prePointLocalPosition
                break
            end
        end
    end

    if self.prePointAvatar and not self.prePointLocalPosition then
        self.prePointAvatar.name='prePoint(NotUse)'
    end
    
    
    --向后找到一个居中点为止
    for i = 1, 10 do
        local nextCfg=self._Control:GetReviewPictures()[self.Id+i]
        if nextCfg then
            local nextPoint=self.CenterPoints[nextCfg.FocusPointUi]
            if nextPoint then
                self.nextPoint=nextPoint
                self.nextPointLocalPosition=Vector3(0,-self.RectTrans.rect.height*i,0)+nextPoint.localPosition
                if self.nextPointAvatar==nil then
                    self.nextPointAvatar=CS.UnityEngine.GameObject('nextPoint')
                    self.nextPointAvatar.transform:SetParent(self.nextPoint.parent)
                end
                self.nextUIId = nextCfg.Id
                self.nextPointAvatar.name='nextPoint'
                self.nextPointAvatar.transform.localPosition=self.nextPointLocalPosition
                break
            end
        end
    end

    if self.nextPointAvatar and not self.nextPointLocalPosition then
        self.nextPointAvatar.name='nextPoint(NotUse)'
    end
end

return XUiGridAnniversaryReview