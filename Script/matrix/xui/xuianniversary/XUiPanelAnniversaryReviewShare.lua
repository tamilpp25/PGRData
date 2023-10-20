local XUiPanelAnniversaryReviewShare=XClass(XUiNode,'XUiPanelAnniversaryReviewShare')

local dropDownMap={
    LongPng=0,
    ShortPng=1
}

local shareCallBackMap=nil

function XUiPanelAnniversaryReviewShare:Init(longPng,shortPng,ctrl)
    self.LongPng=longPng
    self.ShortPng=shortPng
    self.PngCreatorCtrl=ctrl
    self.LongPng:Apply()
    --todo：暂时没有支持短图生成的UI，所以这里必为空
    --self.ShortPng:Apply()
end

function XUiPanelAnniversaryReviewShare:OnStart()
    self.SDKPanel={}
    XTool.InitUiObjectByUi(self.SDKPanel,self.PanelSDK)

    self:InitBaseCb()
    self:InitShareCallBackMap()
    self:InitShareBtns()
end

function XUiPanelAnniversaryReviewShare:OnEnable()
    self:SetPngDisplay(self.BtnScreenWords.value)
end

function XUiPanelAnniversaryReviewShare:OnDestroy()
    if self.LongPng then
        CS.UnityEngine.GameObject.Destroy(self.LongPng)
    end
    if self.ShortPng then
        CS.UnityEngine.GameObject.Destroy(self.ShortPng)
    end
    if self.PngCreatorCtrl then
        self.PngCreatorCtrl:Release()
    end
end

function XUiPanelAnniversaryReviewShare:InitBaseCb()
    self.BtnSave.CallBack=function()
        if self.selectPng then
            self.savePngAddress=XMVCA.XAnniversary:SaveAlbum(self.selectPng)
        end
    end

    self.BtnClose.CallBack=function()
        self:Close()
    end

    self.BtnScreenWords.onValueChanged:AddListener(handler(self,self.SetPngDisplay))
end

function XUiPanelAnniversaryReviewShare:InitShareCallBackMap()
    shareCallBackMap={
        [XEnumConst.Anniversary.SharePlatform.KJQ_Share]=function()
            if self.savePngAddress then
                XMVCA.XAnniversary:ShareAlbum(self.savePngAddress)
            else
                self.savePngAddress=XMVCA.XAnniversary:SaveAlbum(self.selectPng)
                XMVCA.XAnniversary:ShareAlbum(self.savePngAddress)
            end
        end
    }
end

function XUiPanelAnniversaryReviewShare:InitShareBtns()
    --先隐藏所有按钮
    for i=1,10 do
        local btnShare=self.SDKPanel['BtnShare'..i]
        if btnShare then
            btnShare.gameObject:SetActiveEx(false)
        end
    end
    local cfgs=self._Control:GetAnniversaryReivewSharePlatforms()
    for i, v in pairs(cfgs) do
        local btnShare=self.SDKPanel['BtnShare'..v.Id]
        if btnShare then
            btnShare.gameObject:SetActiveEx(true)
            btnShare:SetSprite(v.Icon)
            btnShare:SetNameByGroup(0,v.Desc)
            --映射设置点击回调
            btnShare.CallBack=shareCallBackMap[v.Type]
        end
    end
end

function XUiPanelAnniversaryReviewShare:SetPngDisplay(value)
    if value==dropDownMap.LongPng then
        self.selectPng=self.LongPng
        self.ImagePhoto.gameObject:SetActiveEx(false)
        self.ImagePhotoLong.gameObject:SetActiveEx(true)
        if self.selectPng then
            self.ImagePhotoLong.texture=self.selectPng
        end
        
    elseif value==dropDownMap.ShortPng then
        self.selectPng=self.ShortPng
        self.ImagePhoto.gameObject:SetActiveEx(true)
        self.ImagePhotoLong.gameObject:SetActiveEx(false)
        if self.selectPng then
            self.ImagePhoto.texture=self.selectPng
        end
    end
end

return XUiPanelAnniversaryReviewShare