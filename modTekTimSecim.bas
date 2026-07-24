Attribute VB_Name = "modTekTimSecim"


Option Explicit

Private Const SEPET_EKLENDI_TEKTIM As Long = 1
Private Const SEPET_ZATEN_VAR_TEKTIM As Long = 0
Private Const SEPET_GOREV_CAKISMASI_TEKTIM As Long = -1
Private Const SEPET_GOREV_DEGISTI_TEKTIM As Long = 2
Private Const SEPET_GOREV_DEGISIKLIGI_REDDEDILDI_TEKTIM As Long = -2
Private Const SIRA_FORMULU_TEKTIM As String = "=ROW()-ROW($A$2)"
Private Const YAZDIRMA_BASLIK_SATIRLARI_TEKTIM As String = "$1:$2"
Private Const YARDIMCI_GRUP_KOLONU_TEKTIM As String = "J"
Private Const YARDIMCI_HAZIR_KITA_OZET_KOLONU_TEKTIM As String = "K"
Private Const YARDIMCI_GULUSKUR_OZET_KOLONU_TEKTIM As String = "L"
Private Const YARDIMCI_DIGER_OZET_KOLONU_TEKTIM As String = "M"
Private Const YARDIMCI_SICIL_KOLONU_TEKTIM As String = "N"
Private Const SEPET_BASLIK_ISARETI_TEKTIM As String = "__BASLIK__"
Private Const VERI_SATIR_YUKSEKLIGI_TEKTIM As Double = 18
Private mSonTiklananPersonelSatiri_TekTim As Long

'================================================================
' DOSYA ACILINCA FORMU AC
'================================================================
Public Sub Auto_Open()
    TekTimFormuAc
End Sub

'================================================================
' FORM HAZIRLAMA
'================================================================
Public Sub FormuHazirla_TekTim(ByVal frm As Object)

    PersonelSecimDurumunuSifirla_TekTim
    frm.txtTarih.Value = Format(Date, "dd.mm.yyyy")

    PersonelListesiniHazirla_TekTim frm.lstPersonel
    SepetListesiniHazirla_TekTim frm.lstSecilenler

    TimleriYukle_TekTim frm.cmbTim
    GorevleriYukle_TekTim frm.cmbGorev
    AciklamalariYukle_TekTim AciklamaComboGetir_TekTim(frm)

    frm.cmbTim.ListIndex = -1
    On Error Resume Next
    frm.Label2.Caption = "Gorev"
    DigerAciklamaKutusuGetir_TekTim(frm).Value = ""
    On Error GoTo 0

End Sub

Public Sub FinalYerlesimiUygula_TekTim(ByVal frm As Object)
    ' UserForm_Activate her odak kazaniminda tekrar calisir.
    ' Burada liste temizlemek form acikken yeniden aktivasyonda
    ' beklenmeyen davranis ve yan etkiler uretiyordu.
    PersonelSecimDurumunuSifirla_TekTim
    SepetiOnizlemeSirasinaAl_TekTim frm.lstSecilenler

End Sub

'================================================================
' TIMLERI COMBOBOX'A YUKLE
'================================================================
Public Sub TimleriYukle_TekTim(ByVal cmb As Object)

    Dim ws As Worksheet
    Dim sonSatir As Long
    Dim i As Long
    Dim timAdi As String
    Dim mevcutTimler As Object
    Dim siraliTimlar As Variant
    Dim timKey As Variant

    Set ws = PersonelSayfasiGetir_TekTim(True)
    If ws Is Nothing Then Exit Sub
    Set mevcutTimler = CreateObject("Scripting.Dictionary")
    mevcutTimler.CompareMode = vbTextCompare

    cmb.Clear

    sonSatir = ws.Cells(ws.Rows.Count, "D").End(xlUp).Row

    For i = 2 To sonSatir
        timAdi = Trim(CStr(ws.Cells(i, "D").Value))
        If timAdi <> "" Then
            If Not MetinlerEsit_TekTim(timAdi, GetNobHeyetiMetni_TekTim()) Then
                If Not mevcutTimler.Exists(timAdi) Then
                    mevcutTimler.Add timAdi, timAdi
                End If
            End If
        End If
    Next i

    siraliTimlar = GetSabitTimSirasi_TekTim()

    For Each timKey In siraliTimlar
        If mevcutTimler.Exists(CStr(timKey)) Then
            cmb.AddItem mevcutTimler(CStr(timKey))
        End If
    Next timKey

End Sub

'================================================================
' GOREVLERI COMBOBOX'A YUKLE
'================================================================
Public Sub GorevleriYukle_TekTim(ByVal cmb As Object)

    cmb.Clear

    On Error Resume Next
    cmb.Style = fmStyleDropDownList
    On Error GoTo 0

    cmb.AddItem ""
    cmb.AddItem GetNobHeyetiMetni_TekTim()
    cmb.AddItem GetHazirKitaMetni_TekTim()
    cmb.AddItem GetGuluskurMetni_TekTim()
    cmb.ListIndex = 0

End Sub

'================================================================
' TIM SECILDIGINDE PERSONELLERI LISTELE

'================================================================
' ACIKLAMALARI COMBOBOX'A YUKLE
'================================================================
Public Sub AciklamalariYukle_TekTim(ByVal cmb As Object)

    If cmb Is Nothing Then Exit Sub

    cmb.Clear

    On Error Resume Next
    cmb.Style = fmStyleDropDownList
    On Error GoTo 0

    cmb.AddItem ""
    cmb.AddItem "Heybet Komutani"
    cmb.AddItem "Nob. Sb."
    cmb.AddItem "Garaj Nob."
    cmb.AddItem "TTZA Nob."
    cmb.AddItem "Kule Nob. 1"
    cmb.AddItem "Kule Nob. 2"
    cmb.AddItem "Diger"
    cmb.ListIndex = 0

End Sub

'================================================================
' USERFORM UZERINDEKI SABIT KONTROLLERI GETIR
'================================================================
Private Function AciklamaComboGetir_TekTim(ByVal frm As Object) As Object

    On Error Resume Next
    Set AciklamaComboGetir_TekTim = frm.Controls("cmbAciklamaEx")
    On Error GoTo 0

End Function

Private Function DigerAciklamaKutusuGetir_TekTim(ByVal frm As Object) As Object

    On Error Resume Next
    Set DigerAciklamaKutusuGetir_TekTim = frm.Controls("txtDigerAciklamaEx")
    On Error GoTo 0

End Function

Private Function SeciliAciklamayiGetir_TekTim(ByVal frm As Object) As String

    Dim cmb As Object
    Dim txt As Object
    Dim seciliAciklama As String
    Dim digerAciklama As String

    Set cmb = AciklamaComboGetir_TekTim(frm)
    Set txt = DigerAciklamaKutusuGetir_TekTim(frm)

    If Not cmb Is Nothing Then seciliAciklama = Trim(CStr(cmb.Value))
    If Not txt Is Nothing Then digerAciklama = Trim(CStr(txt.Value))

    If MetinlerEsit_TekTim(seciliAciklama, "Diger") Then
        SeciliAciklamayiGetir_TekTim = digerAciklama
    ElseIf seciliAciklama <> "" Then
        SeciliAciklamayiGetir_TekTim = seciliAciklama
    Else
        SeciliAciklamayiGetir_TekTim = digerAciklama
    End If

End Function
'================================================================
' TIM SECILDIGINDE PERSONELLERI LISTELE
'================================================================
Public Sub TimSecildi_TekTim(ByVal frm As Object)

    Dim ws As Worksheet
    Dim sonSatir As Long
    Dim i As Long
    Dim seciliTim As String
    Dim sicil As String
    Dim rutbe As String
    Dim adSoyad As String
    Dim durum As String
    Dim hucredekiTim As String

    Set ws = PersonelSayfasiGetir_TekTim(True)
    If ws Is Nothing Then Exit Sub
    seciliTim = Trim(CStr(frm.cmbTim.Value))

    PersonelSecimDurumunuSifirla_TekTim
    frm.lstPersonel.Clear

    If seciliTim = "" Then Exit Sub

    sonSatir = ws.Cells(ws.Rows.Count, "D").End(xlUp).Row

    For i = 2 To sonSatir

        sicil = Trim(CStr(ws.Cells(i, "A").Value))
        rutbe = Trim(CStr(ws.Cells(i, "B").Value))
        adSoyad = Trim(CStr(ws.Cells(i, "C").Value))
        durum = Trim(CStr(ws.Cells(i, "E").Value))
        hucredekiTim = Trim(CStr(ws.Cells(i, "D").Value))

        If DurumAktifMi_TekTim(durum) Then
            If MetinlerEsit_TekTim(hucredekiTim, seciliTim) Then
                frm.lstPersonel.AddItem sicil
                frm.lstPersonel.List(frm.lstPersonel.ListCount - 1, 1) = rutbe
                frm.lstPersonel.List(frm.lstPersonel.ListCount - 1, 2) = adSoyad
            End If
        End If

    Next i

End Sub

'================================================================
' SECILEN PERSONELLERI SEPETE EKLE
'================================================================
Public Sub SecilenleriSepeteEkle_TekTim(ByVal frm As Object)

    Dim seciliTim As String
    Dim seciliGorev As String
    Dim seciliAciklama As String
    Dim i As Long
    Dim sonuc As Long
    Dim eklenenSayisi As Long
    Dim atlananSayisi As Long
    Dim gorevDegisenSayisi As Long
    Dim gorevDegisikligiReddedilenSayisi As Long
    Dim mesaj As String

    If Not SecimBilgileriniHazirla_TekTim(frm, seciliTim, seciliGorev, seciliAciklama) Then Exit Sub

    If SeciliKayitSayisi_TekTim(frm.lstPersonel) = 0 Then
        MsgBox "Lutfen sepete eklenecek en az bir personel seciniz.", vbExclamation, "Uyari"
        Exit Sub
    End If

For i = 0 To frm.lstPersonel.ListCount - 1
    If frm.lstPersonel.Selected(i) Then
        sonuc = SepeteSatirEkle_TekTim(frm, i, seciliTim, seciliGorev, seciliAciklama)

        Select Case sonuc
            Case SEPET_EKLENDI_TEKTIM
                eklenenSayisi = eklenenSayisi + 1
            Case SEPET_GOREV_DEGISTI_TEKTIM
                gorevDegisenSayisi = gorevDegisenSayisi + 1
            Case SEPET_GOREV_DEGISIKLIGI_REDDEDILDI_TEKTIM
                gorevDegisikligiReddedilenSayisi = gorevDegisikligiReddedilenSayisi + 1
            Case Else
                atlananSayisi = atlananSayisi + 1
        End Select
    End If
Next i

    Call SepetiOnizlemeSirasinaAl_TekTim(frm.lstSecilenler)

    ListeSeciminiTemizle_TekTim frm.lstPersonel
    SecimAlanlariniTemizle_TekTim frm

    If eklenenSayisi > 0 Then
        mesaj = eklenenSayisi & " personel sepete eklendi."
    ElseIf atlananSayisi > 0 Or gorevDegisenSayisi > 0 Or gorevDegisikligiReddedilenSayisi > 0 Then
        mesaj = "Sepet islemi tamamlandi."
    Else
        mesaj = "Secilen personeller sepete eklenmedi."
    End If

    If atlananSayisi > 0 Then
        mesaj = mesaj & IIf(mesaj <> "", " ", "") & atlananSayisi & " personel zaten sepette vardi."
    End If

    If gorevDegisenSayisi > 0 Then
        mesaj = mesaj & IIf(mesaj <> "", " ", "") & gorevDegisenSayisi & " personelin gorevi guncellendi."
    End If

    If gorevDegisikligiReddedilenSayisi > 0 Then
        mesaj = mesaj & IIf(mesaj <> "", " ", "") & gorevDegisikligiReddedilenSayisi & " gorev degisikligi reddedildi."
    End If

    If mesaj <> "" Then
        MsgBox mesaj, vbInformation, "Bilgi"
    End If

End Sub

'================================================================
' CIFT TIKLANAN PERSONELI SEPETE EKLE
'================================================================
Public Sub SeciliPersoneliSepeteEkle_TekTim(ByVal frm As Object)

    Dim seciliTim As String
    Dim seciliGorev As String
    Dim seciliAciklama As String
    Dim seciliSatir As Long
    Dim sonuc As Long

    If Not SecimBilgileriniHazirla_TekTim(frm, seciliTim, seciliGorev, seciliAciklama) Then Exit Sub

    seciliSatir = SeciliPersonelSatiriniBul_TekTim(frm.lstPersonel)
    If seciliSatir < 0 Then Exit Sub

    sonuc = SepeteSatirEkle_TekTim(frm, seciliSatir, seciliTim, seciliGorev, seciliAciklama)

    Select Case sonuc
        Case SEPET_EKLENDI_TEKTIM
            On Error Resume Next
            frm.lstPersonel.Selected(seciliSatir) = False
            On Error GoTo 0
            Call SepetiOnizlemeSirasinaAl_TekTim(frm.lstSecilenler)
            SecimAlanlariniTemizle_TekTim frm
        Case SEPET_GOREV_DEGISTI_TEKTIM
            Call SepetiOnizlemeSirasinaAl_TekTim(frm.lstSecilenler)
            SecimAlanlariniTemizle_TekTim frm
            MsgBox "Secilen personelin gorevi sepette guncellendi.", vbInformation, "Bilgi"
        Case SEPET_GOREV_DEGISIKLIGI_REDDEDILDI_TEKTIM
            MsgBox "Gorev degisikligi reddedildi. Sepetteki eski gorev korundu.", vbInformation, "Bilgi"
        Case Else
            Call SepetiOnizlemeSirasinaAl_TekTim(frm.lstSecilenler)
            MsgBox "Secilen personel zaten sepette bulunuyor.", vbInformation, "Bilgi"
    End Select
End Sub

Public Sub PersonelListesindeSatirTiklandi_TekTim(ByVal frm As Object)

    On Error Resume Next
    mSonTiklananPersonelSatiri_TekTim = CLng(frm.lstPersonel.ListIndex)
    On Error GoTo 0

End Sub

Private Function SeciliPersonelSatiriniBul_TekTim(ByVal lst As Object) As Long

    Dim i As Long

    SeciliPersonelSatiriniBul_TekTim = -1
    On Error Resume Next

    If mSonTiklananPersonelSatiri_TekTim >= 0 Then
        If mSonTiklananPersonelSatiri_TekTim < lst.ListCount Then
            SeciliPersonelSatiriniBul_TekTim = mSonTiklananPersonelSatiri_TekTim
        End If
    End If

    If SeciliPersonelSatiriniBul_TekTim < 0 Then
        SeciliPersonelSatiriniBul_TekTim = lst.ListIndex
    End If

    If SeciliPersonelSatiriniBul_TekTim < 0 Then
        For i = 0 To lst.ListCount - 1
            If lst.Selected(i) Then
                SeciliPersonelSatiriniBul_TekTim = i
                Exit For
            End If
        Next i
    End If

    On Error GoTo 0

End Function

'================================================================
' SEPetten KAYIT CIKAR
'================================================================
Public Sub SepettenCikar_TekTim(ByVal frm As Object)

    Dim seciliSatir As Long
    Dim timAdi As String
    Dim gorevAdi As String
    Dim adSoyad As String
    Dim mesaj As String

    seciliSatir = frm.lstSecilenler.ListIndex
    If seciliSatir < 0 Then Exit Sub
    If SepetBaslikSatiriMi_TekTim(frm.lstSecilenler, seciliSatir) Then Exit Sub

    timAdi = Trim(CStr(frm.lstSecilenler.List(seciliSatir, 1)))
    gorevAdi = Trim(CStr(frm.lstSecilenler.List(seciliSatir, 2)))
    adSoyad = Trim(CStr(frm.lstSecilenler.List(seciliSatir, 4)))

    mesaj = adSoyad
    If mesaj = "" Then
        mesaj = Trim(CStr(frm.lstSecilenler.List(seciliSatir, 0)))
    End If

    If timAdi <> "" Then
        mesaj = mesaj & " (" & timAdi
        If gorevAdi <> "" Then
            mesaj = mesaj & " - " & gorevAdi
        End If
        mesaj = mesaj & ")"
    End If

    If MsgBox(mesaj & " sepetten cikarilsin mi?", vbQuestion + vbYesNo, "Onay") = vbYes Then
        frm.lstSecilenler.RemoveItem seciliSatir
        Call SepetiOnizlemeSirasinaAl_TekTim(frm.lstSecilenler)
    End If

End Sub

'================================================================
' FORMU TEMIZLE
'================================================================
Public Sub FormuTemizle_TekTim(ByVal frm As Object)

    PersonelSecimDurumunuSifirla_TekTim
    frm.txtTarih.Value = Format(Date, "dd.mm.yyyy")
    frm.cmbTim.ListIndex = -1

    GorevleriYukle_TekTim frm.cmbGorev
    AciklamalariYukle_TekTim AciklamaComboGetir_TekTim(frm)
    If Not AciklamaComboGetir_TekTim(frm) Is Nothing Then AciklamaComboGetir_TekTim(frm).ListIndex = 0
    If Not DigerAciklamaKutusuGetir_TekTim(frm) Is Nothing Then DigerAciklamaKutusuGetir_TekTim(frm).Value = ""

    PersonelListesiniHazirla_TekTim frm.lstPersonel
    SepetListesiniHazirla_TekTim frm.lstSecilenler

End Sub

'================================================================
' LISTE OLUSTUR - SEPETTEKI PERSONELLERI YENI SAYFAYA YAZ
'================================================================
Public Sub ListeOlustur_TekTim(ByVal frm As Object)

    Dim tarihMetni As String
    Dim tarihDegeri As Date
    Dim wsGun As Worksheet
    Dim sayfaAdi As String
    Dim yazSatir As Long
    Dim sepetKayitlar As Collection
    Dim tumKayitlar As Collection
    Dim sicilAnahtarlari As Object
    Dim yedekAnahtarlar As Object
    Dim eklenenSayisi As Long
    Dim atlananSayisi As Long

    On Error GoTo ListeOlusturmaHatasi

    tarihMetni = Trim(CStr(frm.txtTarih.Value))

    If tarihMetni = "" Then
        MsgBox "Tarih giriniz.", vbExclamation, "Uyari"
        Exit Sub
    End If

    If Not TarihMetniniCoz_TekTim(tarihMetni, tarihDegeri) Then
        MsgBox "Tarih gecersiz. Ornek: 08.04.2026", vbExclamation, "Uyari"
        Exit Sub
    End If

    If SepetGercekKayitSayisi_TekTim(frm.lstSecilenler) = 0 Then
        MsgBox "Lutfen once sepete en az bir personel ekleyiniz.", vbExclamation, "Uyari"
        Exit Sub
    End If

    sayfaAdi = Format(tarihDegeri, "dd.mm")

    If SayfaVarMi_TekTim(sayfaAdi) Then
        Call MevcutGunSayfasiniGuncelle_TekTim(frm, sayfaAdi, tarihDegeri)
        Exit Sub
    End If

    Set wsGun = HazirlaGunSayfasi_TekTim(sayfaAdi, tarihDegeri)
    If wsGun Is Nothing Then Exit Sub

    Set sepetKayitlar = SepetKayitlariniTopla_TekTim(frm.lstSecilenler)
    Set tumKayitlar = New Collection
    Set sicilAnahtarlari = CreateObject("Scripting.Dictionary")
    Set yedekAnahtarlar = CreateObject("Scripting.Dictionary")
    sicilAnahtarlari.CompareMode = vbTextCompare
    yedekAnahtarlar.CompareMode = vbTextCompare

    Call KayitKoleksiyonunuBirlesimeEkle_TekTim(sepetKayitlar, tumKayitlar, sicilAnahtarlari, yedekAnahtarlar, eklenenSayisi, atlananSayisi)
    yazSatir = KayitlariSayfayaYaz_TekTim(tumKayitlar, wsGun)
    Call GunSayfasiSonKontrol_TekTim(wsGun, tumKayitlar, yazSatir)
    ' Tazminat takip sayfas?na X i?aretlerini koy
    Call TazminatTakibiGuncelle_TekTim(tarihDegeri)
    MsgBox eklenenSayisi & " personel icin liste olusturuldu: " & sayfaAdi, vbInformation, "Tamam"
    Exit Sub

ListeOlusturmaHatasi:
    MsgBox "Liste olusturulurken hata olustu: " & Err.Description, vbExclamation, "Liste Hatasi"

End Sub

'================================================================
' GUN SAYFASI HAZIRLA
'================================================================
Private Function HazirlaGunSayfasi_TekTim(ByVal sayfaAdi As String, ByVal tarihDegeri As Date) As Worksheet

    Dim ws As Worksheet

    If SayfaVarMi_TekTim(sayfaAdi) Then
        MsgBox sayfaAdi & " adli sayfa zaten var. Guncelleme modu kullanilmali.", vbExclamation, "Uyari"
        Exit Function
    End If

    On Error GoTo SayfaHatasi
    Set ws = ThisWorkbook.Worksheets.Add(After:=Sheets(Sheets.Count))
    ws.Name = sayfaAdi

    Call GunlukSayfaTasarla_TekTim(ws, tarihDegeri)

    Set HazirlaGunSayfasi_TekTim = ws
    Exit Function

SayfaHatasi:
    MsgBox "Gun sayfasi olusturulamadi: " & Err.Description, vbExclamation, "Sayfa Hatasi"

End Function

'================================================================
' GUNLUK SAYFA TASARIMI
'================================================================
Private Sub GunlukSayfaTasarla_TekTim(ByVal ws As Worksheet, ByVal tarihDegeri As Date)

    Dim baslik As String

    baslik = GetBaslikMetni_TekTim()
    If baslik = "" Then
        baslik = "HEYBET TEPE PUSU FAALIYETI ISIM LISTESI"
    End If

    With ws

        .Range("A1:E1").Merge
        .Range("A1").Value = baslik & " - " & Format(tarihDegeri, "dd.mm.yyyy")
        .Range("A1").Font.Bold = True
        .Range("A1").Font.Size = 14
        .Range("A1").HorizontalAlignment = xlCenter
        .Range("A1").VerticalAlignment = xlCenter

        .Range("A2").Value = "S. NU"
        .Range("B2").Value = ChrW(66) & ChrW(304) & "RL" & ChrW(304) & ChrW(286) & ChrW(304)
        .Range("C2").Value = "R" & ChrW(220) & "TBE"
        .Range("D2").Value = "ADI SOYADI"
        .Range("E2").Value = "D" & ChrW(304) & ChrW(286) & "ER"

        .Range("A2:E2").Font.Bold = True
        .Range("A2:E2").HorizontalAlignment = xlCenter
        .Range("A2:E2").VerticalAlignment = xlCenter
        .Range("A2:E2").Interior.Color = RGB(217, 217, 217)

        .Columns("A").ColumnWidth = 7
        .Columns("B").ColumnWidth = 14
        .Columns("C").ColumnWidth = 16
        .Columns("D").ColumnWidth = 28
        .Columns("E").ColumnWidth = 18
        .Columns(YARDIMCI_GRUP_KOLONU_TEKTIM & ":" & YARDIMCI_SICIL_KOLONU_TEKTIM).Hidden = True

    End With

End Sub

'================================================================
' BIRLIK HUCRESI MERGE
'================================================================
Private Sub BirlikHucresiOlustur_TekTim(ByVal ws As Worksheet, ByVal ilkSatir As Long, ByVal sonSatir As Long, ByVal birlikAdi As String)

    With ws.Range("B" & ilkSatir & ":B" & sonSatir)
        .Merge
        .Value = birlikAdi
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
    End With

End Sub

'================================================================
' SON BICIMLENDIRME
'================================================================
Private Sub SonBicimVer_TekTim(ByVal ws As Worksheet, ByVal sonSatir As Long)

    Dim veriSonSatir As Long

    veriSonSatir = sonSatir
    If sonSatir < 3 Then sonSatir = 3

    If veriSonSatir >= 3 Then
        ws.Range("A3:A" & veriSonSatir).Formula = SIRA_FORMULU_TEKTIM
    End If

    With ws.Range("A2:E" & sonSatir)
        .Borders.LineStyle = xlContinuous
        .Borders.Weight = xlThin
        .VerticalAlignment = xlCenter
    End With

    ws.Range("A3:A" & sonSatir).HorizontalAlignment = xlCenter
    ws.Range("C3:D" & sonSatir).HorizontalAlignment = xlLeft
    ws.Range("D3:E" & sonSatir).WrapText = True
    ws.Rows("3:" & CStr(sonSatir)).RowHeight = VERI_SATIR_YUKSEKLIGI_TEKTIM

End Sub

Private Sub GrupRaporBloguYaz_TekTim(ByVal ws As Worksheet, ByVal baslangicSatiri As Long, ByVal ilkKolon As String, ByVal sonKolon As String, ByVal baslik As String, ByVal grupKodu As String, ByVal yardimciKolon As String, ByVal rutbeSatirlari As Collection, ByVal satirSayisi As Long)

    Dim baslikAlani As Range
    Dim icerikAlani As Range
    Dim icerikSatiri As Long
    Dim yardimciSatirSayisi As Long

    Set baslikAlani = ws.Range(ilkKolon & CStr(baslangicSatiri) & ":" & sonKolon & CStr(baslangicSatiri))
    Set icerikAlani = ws.Range(ilkKolon & CStr(baslangicSatiri + 1) & ":" & sonKolon & CStr(baslangicSatiri + 1))
    icerikSatiri = baslangicSatiri + 1

    baslikAlani.Merge
    icerikAlani.Merge

    With baslikAlani
        .Value = baslik
        .Font.Bold = True
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        .Interior.Color = RGB(217, 217, 217)
        .Borders.LineStyle = xlContinuous
        .Borders.Weight = xlThin
    End With

    yardimciSatirSayisi = GrupOzetiYardimciFormulleriniYaz_TekTim(ws, yardimciKolon, icerikSatiri, grupKodu, rutbeSatirlari)

    With icerikAlani
        .WrapText = True
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlTop
        .Borders.LineStyle = xlContinuous
        .Borders.Weight = xlThin
    End With

    icerikAlani.Cells(1, 1).Formula = GrupOzetiIcerikFormulunuOlustur_TekTim(yardimciKolon, icerikSatiri, yardimciSatirSayisi)

    ws.Rows(baslangicSatiri).RowHeight = 20
    ws.Rows(baslangicSatiri + 1).RowHeight = IIf(satirSayisi < 4, 60, satirSayisi * 15)

End Sub

Private Function GrupOzetiSatirSayisiGetir_TekTim(ByVal rutbeSatirlari As Collection) As Long

    GrupOzetiSatirSayisiGetir_TekTim = rutbeSatirlari.Count + 1

End Function

Private Function GrupOzetiYardimciFormulleriniYaz_TekTim(ByVal ws As Worksheet, ByVal yardimciKolon As String, ByVal ilkSatir As Long, ByVal grupKodu As String, ByVal rutbeSatirlari As Collection) As Long

    Dim rutbe As Variant
    Dim yazSatir As Long

    yazSatir = ilkSatir

    For Each rutbe In rutbeSatirlari
        ws.Cells(yazSatir, yardimciKolon).Formula = "=""" & ExcelMetniKacisla_TekTim(CStr(rutbe) & " ") & """&COUNTIFS($" & YARDIMCI_GRUP_KOLONU_TEKTIM & ":$" & YARDIMCI_GRUP_KOLONU_TEKTIM & ",""" & ExcelMetniKacisla_TekTim(grupKodu) & """,$C:$C,""" & ExcelMetniKacisla_TekTim(CStr(rutbe)) & """,$D:$D,""<>"")"
        yazSatir = yazSatir + 1
    Next rutbe

    ws.Cells(yazSatir, yardimciKolon).Formula = "=""" & ExcelMetniKacisla_TekTim("Toplam ") & """&COUNTIFS($" & YARDIMCI_GRUP_KOLONU_TEKTIM & ":$" & YARDIMCI_GRUP_KOLONU_TEKTIM & ",""" & ExcelMetniKacisla_TekTim(grupKodu) & """,$D:$D,""<>"")"
    GrupOzetiYardimciFormulleriniYaz_TekTim = yazSatir - ilkSatir + 1

End Function

Private Function GrupOzetiIcerikFormulunuOlustur_TekTim(ByVal yardimciKolon As String, ByVal ilkSatir As Long, ByVal satirSayisi As Long) As String

    Dim i As Long
    Dim formulaMetni As String

    formulaMetni = "=" & yardimciKolon & CStr(ilkSatir)

    For i = 1 To satirSayisi - 1
        formulaMetni = formulaMetni & "&CHAR(10)&" & yardimciKolon & CStr(ilkSatir + i)
    Next i

    GrupOzetiIcerikFormulunuOlustur_TekTim = formulaMetni

End Function

Private Function ExcelMetniKacisla_TekTim(ByVal metin As String) As String

    ExcelMetniKacisla_TekTim = Replace(CStr(metin), """", """""")

End Function

Private Function MaksimumDeger_TekTim(ByVal deger1 As Long, ByVal deger2 As Long, ByVal deger3 As Long) As Long

    MaksimumDeger_TekTim = deger1
    If deger2 > MaksimumDeger_TekTim Then MaksimumDeger_TekTim = deger2
    If deger3 > MaksimumDeger_TekTim Then MaksimumDeger_TekTim = deger3

End Function

Private Sub MevcutGunSayfasiniGuncelle_TekTim(ByVal frm As Object, ByVal sayfaAdi As String, ByVal tarihDegeri As Date)

    Dim wsGun As Worksheet
    Dim tumKayitlar As Collection
    Dim mevcutKayitlar As Collection
    Dim sepetKayitlar As Collection
    Dim sicilAnahtarlari As Object
    Dim yedekAnahtarlar As Object
    Dim yazSatir As Long
    Dim eklenenSayisi As Long
    Dim atlananSayisi As Long
    Dim korunanSayisi As Long
    Dim eslesenElleSayisi As Long
    Dim sicilsizKorunanSayisi As Long
    Dim gorevDegisenSayisi As Long
    Dim gorevDegisikligiReddedilenSayisi As Long
    Dim degismedenKorunanSayisi As Long

    On Error GoTo GuncellemeHatasi

    Set wsGun = ThisWorkbook.Worksheets(sayfaAdi)
    If Not GunSayfasiYedeginiOlustur_TekTim(wsGun, sayfaAdi) Then
        MsgBox "Yedek sayfa olusturulamadigi icin guncelleme iptal edildi.", vbExclamation, "Guncelleme Iptal"
        Exit Sub
    End If

    Set tumKayitlar = New Collection
    Set sicilAnahtarlari = CreateObject("Scripting.Dictionary")
    Set yedekAnahtarlar = CreateObject("Scripting.Dictionary")
    sicilAnahtarlari.CompareMode = vbTextCompare
    yedekAnahtarlar.CompareMode = vbTextCompare

    Set mevcutKayitlar = MevcutSayfaKayitlariniOku_TekTim(wsGun, eslesenElleSayisi, sicilsizKorunanSayisi)
    Call KayitKoleksiyonunuBirlesimeEkle_TekTim(mevcutKayitlar, tumKayitlar, sicilAnahtarlari, yedekAnahtarlar, korunanSayisi, atlananSayisi)

    Set sepetKayitlar = SepetKayitlariniTopla_TekTim(frm.lstSecilenler)
    Call KayitKoleksiyonunuOnayliBirlesimeEkle_TekTim(sepetKayitlar, tumKayitlar, sicilAnahtarlari, yedekAnahtarlar, eklenenSayisi, atlananSayisi, gorevDegisenSayisi, gorevDegisikligiReddedilenSayisi)

    Call GunSayfasiniTemizle_TekTim(wsGun)
    Call GunlukSayfaTasarla_TekTim(wsGun, tarihDegeri)
    yazSatir = KayitlariSayfayaYaz_TekTim(tumKayitlar, wsGun)
    Call GunSayfasiSonKontrol_TekTim(wsGun, tumKayitlar, yazSatir)

    degismedenKorunanSayisi = korunanSayisi - gorevDegisenSayisi
    If degismedenKorunanSayisi < 0 Then degismedenKorunanSayisi = 0
    ' Tazminat takip sayfas?na X i?aretlerini koy
    Call TazminatTakibiGuncelle_TekTim(DateAdd("d", 1, tarihDegeri))
    MsgBox degismedenKorunanSayisi & " mevcut kayit korundu. " & eklenenSayisi & " yeni kayit eklendi. " & _
        atlananSayisi & " tekrar kayit atlandi. " & gorevDegisenSayisi & " gorev degisikligi yapildi. " & _
        gorevDegisikligiReddedilenSayisi & " gorev degisikligi reddedildi. " & eslesenElleSayisi & " elle kayit sicille eslesti. " & _
        sicilsizKorunanSayisi & " kayit sicilsiz korundu: " & sayfaAdi, vbInformation, "Guncelleme Tamam"
    Exit Sub

GuncellemeHatasi:
    MsgBox "Sayfa guncellenirken hata olustu: " & Err.Description, vbExclamation, "Guncelleme Hatasi"

End Sub

Private Function GunSayfasiYedeginiOlustur_TekTim(ByVal ws As Worksheet, ByVal sayfaAdi As String) As Boolean

    Dim yedekAdi As String
    Dim geciciYedekAdi As String
    Dim oncekiUyariDurumu As Boolean
    Dim eskiYedek As Worksheet
    Dim yeniYedek As Worksheet

    On Error GoTo YedekHatasi

    oncekiUyariDurumu = Application.DisplayAlerts
    yedekAdi = SabitYedekSayfaAdi_TekTim(sayfaAdi)
    geciciYedekAdi = BenzersizGeciciYedekSayfaAdi_TekTim(sayfaAdi)

    ws.Copy After:=ws
    Set yeniYedek = ActiveSheet
    yeniYedek.Name = geciciYedekAdi

    If SayfaVarMi_TekTim(yedekAdi) Then
        Set eskiYedek = ThisWorkbook.Worksheets(yedekAdi)
        Application.DisplayAlerts = False
        eskiYedek.Delete
        Application.DisplayAlerts = oncekiUyariDurumu
    End If

    yeniYedek.Name = yedekAdi
    ws.Activate
    GunSayfasiYedeginiOlustur_TekTim = True
    Exit Function

YedekHatasi:
    On Error Resume Next
    Application.DisplayAlerts = oncekiUyariDurumu
    If Not yeniYedek Is Nothing Then
        If SayfaVarMi_TekTim(geciciYedekAdi) Then
            Application.DisplayAlerts = False
            yeniYedek.Delete
            Application.DisplayAlerts = oncekiUyariDurumu
        End If
    End If
    ws.Activate
    On Error GoTo 0
    GunSayfasiYedeginiOlustur_TekTim = False

End Function

Private Function SabitYedekSayfaAdi_TekTim(ByVal sayfaAdi As String) As String

    SabitYedekSayfaAdi_TekTim = Left$(sayfaAdi & "_yedek", 31)

End Function

Private Function BenzersizGeciciYedekSayfaAdi_TekTim(ByVal sayfaAdi As String) As String

    Dim temelAd As String
    Dim aday As String
    Dim sira As Long

    temelAd = Left$(sayfaAdi & "_tmp_" & Format(Now, "hhmmss"), 31)
    aday = temelAd

    Do While SayfaVarMi_TekTim(aday)
        sira = sira + 1
        aday = Left$(temelAd, 28) & "_" & CStr(sira)
    Loop

    BenzersizGeciciYedekSayfaAdi_TekTim = aday

End Function

Private Function MevcutSayfaKayitlariniOku_TekTim(ByVal ws As Worksheet, ByRef eslesenElleSayisi As Long, ByRef sicilsizKorunanSayisi As Long) As Collection

    Dim kayitlar As Collection
    Dim sonSatir As Long
    Dim satir As Long
    Dim sicil As String
    Dim rutbe As String
    Dim adSoyad As String
    Dim timAdi As String
    Dim gorevAdi As String
    Dim aciklama As String
    Dim grupKodu As String
    Dim bulunanSicil As String

    Set kayitlar = New Collection
    sonSatir = MevcutSayfaSonVeriSatiri_TekTim(ws)

    For satir = 3 To sonSatir
        adSoyad = Trim(CStr(ws.Cells(satir, "D").Value))
        If adSoyad <> "" Then
            rutbe = Trim(CStr(ws.Cells(satir, "C").Value))
            timAdi = MevcutSatirTimMetni_TekTim(ws, satir)
            gorevAdi = MevcutSatirGorevMetni_TekTim(ws, satir)
            aciklama = MevcutSatirAciklamaMetni_TekTim(ws, satir, gorevAdi)
            grupKodu = MevcutSatirGrupKodu_TekTim(ws, satir, gorevAdi, timAdi)
            sicil = Trim(CStr(ws.Cells(satir, YARDIMCI_SICIL_KOLONU_TEKTIM).Value))

            If sicil = "" Then
                bulunanSicil = PersonelSicilBul_TekTim(adSoyad, rutbe, timAdi)
                If bulunanSicil <> "" Then
                    sicil = bulunanSicil
                    eslesenElleSayisi = eslesenElleSayisi + 1
                Else
                    sicilsizKorunanSayisi = sicilsizKorunanSayisi + 1
                End If
            End If

            timAdi = MevcutOzelGorevTiminiDuzelt_TekTim(sicil, adSoyad, rutbe, timAdi, grupKodu)

            kayitlar.Add KayitOlustur_TekTim(sicil, timAdi, gorevAdi, rutbe, adSoyad, aciklama, grupKodu)
        End If
    Next satir

    Set MevcutSayfaKayitlariniOku_TekTim = kayitlar

End Function

Private Function MevcutSayfaSonVeriSatiri_TekTim(ByVal ws As Worksheet) As Long

    Dim printArea As String
    Dim dolarYeri As Long
    Dim sonSatir As Long
    Dim satir As Long

    printArea = CStr(ws.PageSetup.printArea)
    dolarYeri = InStrRev(printArea, "$")

    If dolarYeri > 0 Then
        On Error Resume Next
        sonSatir = CLng(Mid$(printArea, dolarYeri + 1))
        On Error GoTo 0
    End If

    If sonSatir < 3 Then
        sonSatir = ws.Cells(ws.Rows.Count, "D").End(xlUp).Row
        For satir = 3 To sonSatir
            If Trim(CStr(ws.Cells(satir, "B").Value)) = "" _
                And Trim(CStr(ws.Cells(satir, "C").Value)) = "" _
                And Trim(CStr(ws.Cells(satir, "D").Value)) = "" _
                And Trim(CStr(ws.Cells(satir, "E").Value)) = "" Then
                sonSatir = satir - 1
                Exit For
            End If
        Next satir
    End If

    If sonSatir < 3 Then sonSatir = 2
    MevcutSayfaSonVeriSatiri_TekTim = sonSatir

End Function

Private Function MevcutSatirTimMetni_TekTim(ByVal ws As Worksheet, ByVal satir As Long) As String
    MevcutSatirTimMetni_TekTim = Trim(CStr(BirlesikHucreDegeri_TekTim(ws.Cells(satir, "B"))))
End Function

Private Function MevcutOzelGorevTiminiDuzelt_TekTim(ByVal sicil As String, ByVal adSoyad As String, ByVal rutbe As String, ByVal timAdi As String, ByVal grupKodu As String) As String

    Dim bulunanTim As String

    MevcutOzelGorevTiminiDuzelt_TekTim = timAdi
    If Not OzelGrupKoduMu_TekTim(grupKodu) Then Exit Function
    If Not BolukAdiMi_TekTim(timAdi) Then Exit Function

    bulunanTim = PersonelTimBul_TekTim(sicil, adSoyad, rutbe, timAdi)
    If bulunanTim <> "" Then
        MevcutOzelGorevTiminiDuzelt_TekTim = bulunanTim
    End If

End Function

Private Function MevcutSatirGorevMetni_TekTim(ByVal ws As Worksheet, ByVal satir As Long) As String

    Dim eMetni As String
    Dim bMetni As String

    eMetni = Trim(CStr(BirlesikHucreDegeri_TekTim(ws.Cells(satir, "E"))))
    bMetni = MevcutSatirTimMetni_TekTim(ws, satir)

    If MetinlerEsit_TekTim(eMetni, GetHazirKitaBuyukMetni_TekTim()) Or MetinlerEsit_TekTim(eMetni, GetHazirKitaMetni_TekTim()) Then
        MevcutSatirGorevMetni_TekTim = GetHazirKitaMetni_TekTim()
    ElseIf MetinlerEsit_TekTim(eMetni, GetGuluskurBuyukMetni_TekTim()) Or MetinlerEsit_TekTim(eMetni, GetGuluskurMetni_TekTim()) Then
        MevcutSatirGorevMetni_TekTim = GetGuluskurMetni_TekTim()
    ElseIf MetinlerEsit_TekTim(bMetni, GetNobHeyetiMetni_TekTim()) Then
        MevcutSatirGorevMetni_TekTim = GetNobHeyetiMetni_TekTim()
    Else
        MevcutSatirGorevMetni_TekTim = ""
    End If

End Function

Private Function MevcutSatirAciklamaMetni_TekTim(ByVal ws As Worksheet, ByVal satir As Long, ByVal gorevAdi As String) As String

    Dim eMetni As String

    eMetni = Trim(CStr(BirlesikHucreDegeri_TekTim(ws.Cells(satir, "E"))))

    If MetinlerEsit_TekTim(gorevAdi, GetHazirKitaMetni_TekTim()) Or MetinlerEsit_TekTim(gorevAdi, GetGuluskurMetni_TekTim()) Then
        MevcutSatirAciklamaMetni_TekTim = ""
    Else
        MevcutSatirAciklamaMetni_TekTim = eMetni
    End If

End Function

Private Function MevcutSatirGrupKodu_TekTim(ByVal ws As Worksheet, ByVal satir As Long, ByVal gorevAdi As String, ByVal timAdi As String) As String

    Dim grupKodu As String

    grupKodu = Trim(CStr(ws.Cells(satir, YARDIMCI_GRUP_KOLONU_TEKTIM).Value))

    Select Case NormalizeMetin_TekTim(grupKodu)
        Case "HAZIR_KITA", "GULUSKUR", "DIGER"
            MevcutSatirGrupKodu_TekTim = NormalizeMetin_TekTim(grupKodu)
            Exit Function
    End Select

    If MetinlerEsit_TekTim(gorevAdi, GetHazirKitaMetni_TekTim()) Then
        MevcutSatirGrupKodu_TekTim = "HAZIR_KITA"
    ElseIf MetinlerEsit_TekTim(gorevAdi, GetGuluskurMetni_TekTim()) Then
        MevcutSatirGrupKodu_TekTim = "GULUSKUR"
    Else
        MevcutSatirGrupKodu_TekTim = "DIGER"
    End If

End Function

Private Function BirlesikHucreDegeri_TekTim(ByVal hucre As Range) As String

    If hucre.MergeCells Then
        BirlesikHucreDegeri_TekTim = CStr(hucre.MergeArea.Cells(1, 1).Value)
    Else
        BirlesikHucreDegeri_TekTim = CStr(hucre.Value)
    End If

End Function

Private Function SepetKayitlariniTopla_TekTim(ByVal lst As Object) As Collection

    Dim kayitlar As Collection
    Dim i As Long
    Dim sicil As String
    Dim timAdi As String
    Dim gorevAdi As String
    Dim rutbe As String
    Dim adSoyad As String
    Dim aciklama As String
    Dim digerMetni As String
    Dim grupKodu As String

    Set kayitlar = New Collection

    For i = 0 To lst.ListCount - 1
        If SepetBaslikSatiriMi_TekTim(lst, i) Then GoTo SonrakiSepetSatiri

        sicil = Trim(CStr(lst.List(i, 0)))
        timAdi = Trim(CStr(lst.List(i, 1)))
        gorevAdi = Trim(CStr(lst.List(i, 2)))
        rutbe = Trim(CStr(lst.List(i, 3)))
        adSoyad = Trim(CStr(lst.List(i, 4)))
        aciklama = Trim(CStr(lst.List(i, 5)))

        If adSoyad <> "" Then
            digerMetni = KayitDigerMetni_TekTim(gorevAdi, aciklama)
            grupKodu = GorevIcinGrupKoduGetir_TekTim(gorevAdi)
            kayitlar.Add KayitOlustur_TekTim(sicil, timAdi, gorevAdi, rutbe, adSoyad, digerMetni, grupKodu)
        End If

SonrakiSepetSatiri:
    Next i

    Set SepetKayitlariniTopla_TekTim = kayitlar

End Function

Private Function SepetGercekKayitSayisi_TekTim(ByVal lst As Object) As Long

    Dim i As Long

    For i = 0 To lst.ListCount - 1
        If Not SepetBaslikSatiriMi_TekTim(lst, i) Then
            If Trim(CStr(lst.List(i, 4))) <> "" Then
                SepetGercekKayitSayisi_TekTim = SepetGercekKayitSayisi_TekTim + 1
            End If
        End If
    Next i

End Function

Private Function SepetBaslikSatiriMi_TekTim(ByVal lst As Object, ByVal satir As Long) As Boolean

    If satir < 0 Then Exit Function
    If satir >= lst.ListCount Then Exit Function

    SepetBaslikSatiriMi_TekTim = MetinlerEsit_TekTim(CStr(lst.List(satir, 0)), SEPET_BASLIK_ISARETI_TEKTIM)

End Function

Private Sub SepetiOnizlemeSirasinaAl_TekTim(ByVal lst As Object)

    Dim kayitlar As Collection

    Set kayitlar = SepetKayitlariniTopla_TekTim(lst)
    Call SepetListesiniHazirla_TekTim(lst)

    If kayitlar.Count = 0 Then Exit Sub
    Call SepetKayitlariniOnizlemeOlarakYaz_TekTim(kayitlar, lst)

End Sub

Private Sub SepetKayitlariniOnizlemeOlarakYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object)

    Dim yazilanAnahtarlar As Object
    Dim timSirasi As Variant
    Dim timKey As Variant

    Set yazilanAnahtarlar = CreateObject("Scripting.Dictionary")
    yazilanAnahtarlar.CompareMode = vbTextCompare

    Call SepetDigerGorevKayitlariniYaz_TekTim(kayitlar, lst, GetNobHeyetiMetni_TekTim(), GetNobHeyetiMetni_TekTim(), yazilanAnahtarlar)

    timSirasi = GetSabitTimSirasi_TekTim()
    For Each timKey In timSirasi
        Call SepetDigerTimKayitlariniYaz_TekTim(kayitlar, lst, CStr(timKey), yazilanAnahtarlar)
    Next timKey

    Call SepetOzelGrupKayitlariniYaz_TekTim(kayitlar, lst, yazilanAnahtarlar)
    Call SepetKalanKayitlariYaz_TekTim(kayitlar, lst, yazilanAnahtarlar)

End Sub

Private Sub SepetDigerGorevKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal hedefGorev As String, ByVal baslik As String, ByVal yazilanAnahtarlar As Object)

    Dim baslikSatiri As Long
    Dim yazilanSayisi As Long

    baslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, baslik, "")
    yazilanSayisi = SepetRutbeSiraliKayitlariYaz_TekTim(kayitlar, lst, "", hedefGorev, "DIGER", yazilanAnahtarlar, True)
    If yazilanSayisi = 0 Then lst.RemoveItem baslikSatiri

End Sub

Private Sub SepetDigerTimKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal timAdi As String, ByVal yazilanAnahtarlar As Object)

    Dim baslikSatiri As Long
    Dim yazilanSayisi As Long

    baslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, timAdi, "")
    yazilanSayisi = SepetRutbeSiraliKayitlariYaz_TekTim(kayitlar, lst, timAdi, "", "DIGER", yazilanAnahtarlar, False)
    If yazilanSayisi = 0 Then lst.RemoveItem baslikSatiri

End Sub

Private Sub SepetOzelGrupKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal yazilanAnahtarlar As Object)

    Dim bolukler As Variant
    Dim boluk As Variant
    Dim bolukBaslikSatiri As Long
    Dim bolukYazilanSayisi As Long

    bolukler = Array(GetBirinciBolukMetni_TekTim(), GetIkinciBolukMetni_TekTim(), GetUcuncuBolukMetni_TekTim())

    For Each boluk In bolukler
        bolukBaslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, CStr(boluk), "")
        bolukYazilanSayisi = 0

        bolukYazilanSayisi = bolukYazilanSayisi + SepetOzelBolukGorevKayitlariniYaz_TekTim(kayitlar, lst, CStr(boluk), GetHazirKitaMetni_TekTim(), "HAZIR_KITA", yazilanAnahtarlar)
        bolukYazilanSayisi = bolukYazilanSayisi + SepetOzelBolukGorevKayitlariniYaz_TekTim(kayitlar, lst, CStr(boluk), GetGuluskurMetni_TekTim(), "GULUSKUR", yazilanAnahtarlar)

        If bolukYazilanSayisi = 0 Then lst.RemoveItem bolukBaslikSatiri
    Next boluk

    Call SepetOzelGrupDisiTimKayitlariniYaz_TekTim(kayitlar, lst, yazilanAnahtarlar)

End Sub

Private Sub SepetOzelGrupDisiTimKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal yazilanAnahtarlar As Object)

    Dim timler As Collection
    Dim eklenenTimler As Object
    Dim kayit As Variant
    Dim timAdi As Variant
    Dim timKey As String
    Dim timBaslikSatiri As Long
    Dim timYazilanSayisi As Long

    Set timler = New Collection
    Set eklenenTimler = CreateObject("Scripting.Dictionary")
    eklenenTimler.CompareMode = vbTextCompare

    For Each kayit In kayitlar
        If MetinlerEsit_TekTim(CStr(kayit("grup")), "HAZIR_KITA") Or MetinlerEsit_TekTim(CStr(kayit("grup")), "GULUSKUR") Then
            timKey = NormalizeMetin_TekTim(CStr(kayit("tim")))
            If timKey <> "" Then
                If GetBolukAdi_TekTim(CStr(kayit("tim"))) = "" And Not BolukAdiMi_TekTim(CStr(kayit("tim"))) Then
                    If Not eklenenTimler.Exists(timKey) Then
                        eklenenTimler.Add timKey, True
                        timler.Add CStr(kayit("tim"))
                    End If
                End If
            End If
        End If
    Next kayit

    For Each timAdi In timler
        timBaslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, CStr(timAdi), "")
        timYazilanSayisi = 0
        timYazilanSayisi = timYazilanSayisi + SepetOzelTimGrubuKayitlariniYaz_TekTim(kayitlar, lst, CStr(timAdi), GetHazirKitaMetni_TekTim(), "HAZIR_KITA", yazilanAnahtarlar)
        timYazilanSayisi = timYazilanSayisi + SepetOzelTimGrubuKayitlariniYaz_TekTim(kayitlar, lst, CStr(timAdi), GetGuluskurMetni_TekTim(), "GULUSKUR", yazilanAnahtarlar)
        If timYazilanSayisi = 0 Then lst.RemoveItem timBaslikSatiri
    Next timAdi

End Sub

Private Function SepetOzelTimGrubuKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal timAdi As String, ByVal gorevAdi As String, ByVal grupKodu As String, ByVal yazilanAnahtarlar As Object) As Long

    Dim baslikSatiri As Long
    Dim yazilanSayisi As Long

    baslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, timAdi, gorevAdi)
    yazilanSayisi = SepetRutbeSiraliKayitlariYaz_TekTim(kayitlar, lst, timAdi, gorevAdi, grupKodu, yazilanAnahtarlar, False)
    If yazilanSayisi = 0 Then
        lst.RemoveItem baslikSatiri
    Else
        SepetOzelTimGrubuKayitlariniYaz_TekTim = yazilanSayisi
    End If

End Function

Private Function SepetOzelBolukGorevKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal bolukAdi As String, ByVal gorevAdi As String, ByVal grupKodu As String, ByVal yazilanAnahtarlar As Object) As Long

    Dim baslikSatiri As Long
    Dim timSirasi As Variant
    Dim timKey As Variant
    Dim yazilanSayisi As Long

    baslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, bolukAdi, gorevAdi)
    timSirasi = GetSabitTimSirasi_TekTim()

    For Each timKey In timSirasi
        If MetinlerEsit_TekTim(GetBolukAdi_TekTim(CStr(timKey)), bolukAdi) Then
            yazilanSayisi = yazilanSayisi + SepetRutbeSiraliKayitlariYaz_TekTim(kayitlar, lst, CStr(timKey), gorevAdi, grupKodu, yazilanAnahtarlar, False)
        End If
    Next timKey

    yazilanSayisi = yazilanSayisi + SepetRutbeSiraliKayitlariYaz_TekTim(kayitlar, lst, bolukAdi, gorevAdi, grupKodu, yazilanAnahtarlar, False)

    If yazilanSayisi = 0 Then
        lst.RemoveItem baslikSatiri
    Else
        SepetOzelBolukGorevKayitlariniYaz_TekTim = yazilanSayisi
    End If

End Function

Private Sub SepetKalanKayitlariYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal yazilanAnahtarlar As Object)

    Dim kayit As Variant
    Dim anahtar As String
    Dim baslikSatiri As Long
    Dim yazilanSayisi As Long

    baslikSatiri = SepetBaslikSatiriEkle_TekTim(lst, "ESLESMEYEN / ELLE EKLENEN", "")

    For Each kayit In kayitlar
        anahtar = KayitTekilAnahtari_TekTim(kayit)
        If Not yazilanAnahtarlar.Exists(anahtar) Then
            Call SepetKayitSatiriEkle_TekTim(lst, kayit)
            yazilanAnahtarlar.Add anahtar, True
            yazilanSayisi = yazilanSayisi + 1
        End If
    Next kayit

    If yazilanSayisi = 0 Then lst.RemoveItem baslikSatiri

End Sub

Private Function SepetRutbeSiraliKayitlariYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal hedefTim As String, ByVal hedefGorev As String, ByVal hedefGrup As String, ByVal yazilanAnahtarlar As Object, ByVal gorevAnaBlok As Boolean) As Long

    Dim rutbeSirasi As Variant
    Dim rutbe As Variant

    rutbeSirasi = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim(), "")

    For Each rutbe In rutbeSirasi
        SepetRutbeSiraliKayitlariYaz_TekTim = SepetRutbeSiraliKayitlariYaz_TekTim + _
            SepetFiltreliKayitlariYaz_TekTim(kayitlar, lst, hedefTim, hedefGorev, CStr(rutbe), (CStr(rutbe) <> ""), hedefGrup, yazilanAnahtarlar, gorevAnaBlok)
    Next rutbe

End Function

Private Function SepetFiltreliKayitlariYaz_TekTim(ByVal kayitlar As Collection, ByVal lst As Object, ByVal hedefTim As String, ByVal hedefGorev As String, ByVal hedefRutbe As String, ByVal sadeceHedefRutbe As Boolean, ByVal hedefGrup As String, ByVal yazilanAnahtarlar As Object, ByVal gorevAnaBlok As Boolean) As Long

    Dim kayit As Variant
    Dim anahtar As String

    For Each kayit In kayitlar
        anahtar = KayitTekilAnahtari_TekTim(kayit)
        If Not yazilanAnahtarlar.Exists(anahtar) Then
            If KayitFiltreyeUyar_TekTim(kayit, hedefTim, hedefGorev, hedefRutbe, sadeceHedefRutbe, hedefGrup, gorevAnaBlok) Then
                Call SepetKayitSatiriEkle_TekTim(lst, kayit)
                yazilanAnahtarlar.Add anahtar, True
                SepetFiltreliKayitlariYaz_TekTim = SepetFiltreliKayitlariYaz_TekTim + 1
            End If
        End If
    Next kayit

End Function

Private Function SepetBaslikSatiriEkle_TekTim(ByVal lst As Object, ByVal baslik As String, ByVal gorevAdi As String) As Long

    lst.AddItem SEPET_BASLIK_ISARETI_TEKTIM
    SepetBaslikSatiriEkle_TekTim = lst.ListCount - 1

    If gorevAdi <> "" Then
        lst.List(SepetBaslikSatiriEkle_TekTim, 1) = baslik
        lst.List(SepetBaslikSatiriEkle_TekTim, 2) = gorevAdi
    Else
        lst.List(SepetBaslikSatiriEkle_TekTim, 1) = baslik
        lst.List(SepetBaslikSatiriEkle_TekTim, 4) = "== " & baslik & " =="
    End If

End Function

Private Sub SepetKayitSatiriEkle_TekTim(ByVal lst As Object, ByVal kayit As Object)

    Dim yeniSatir As Long

    lst.AddItem CStr(kayit("sicil"))
    yeniSatir = lst.ListCount - 1

    lst.List(yeniSatir, 1) = CStr(kayit("tim"))
    lst.List(yeniSatir, 2) = CStr(kayit("gorev"))
    lst.List(yeniSatir, 3) = CStr(kayit("rutbe"))
    lst.List(yeniSatir, 4) = CStr(kayit("ad"))
    lst.List(yeniSatir, 5) = CStr(kayit("aciklama"))

End Sub

Private Function KayitOlustur_TekTim(ByVal sicil As String, ByVal timAdi As String, ByVal gorevAdi As String, ByVal rutbe As String, ByVal adSoyad As String, ByVal aciklama As String, ByVal grupKodu As String) As Object

    Dim kayit As Object

    Set kayit = CreateObject("Scripting.Dictionary")
    kayit.CompareMode = vbTextCompare

    kayit.Add "sicil", Trim(CStr(sicil))
    kayit.Add "tim", Trim(CStr(timAdi))
    kayit.Add "gorev", Trim(CStr(gorevAdi))
    kayit.Add "rutbe", Trim(CStr(rutbe))
    kayit.Add "ad", Trim(CStr(adSoyad))
    kayit.Add "aciklama", Trim(CStr(aciklama))
    kayit.Add "grup", KayitGrupKodunuDogrula_TekTim(grupKodu, gorevAdi)

    Set KayitOlustur_TekTim = kayit

End Function

Private Function KayitGrupKodunuDogrula_TekTim(ByVal grupKodu As String, ByVal gorevAdi As String) As String

    Select Case NormalizeMetin_TekTim(grupKodu)
        Case "HAZIR_KITA"
            KayitGrupKodunuDogrula_TekTim = "HAZIR_KITA"
        Case "GULUSKUR"
            KayitGrupKodunuDogrula_TekTim = "GULUSKUR"
        Case "DIGER"
            KayitGrupKodunuDogrula_TekTim = "DIGER"
        Case Else
            KayitGrupKodunuDogrula_TekTim = GorevIcinGrupKoduGetir_TekTim(gorevAdi)
    End Select

End Function

Private Sub KayitKoleksiyonunuBirlesimeEkle_TekTim(ByVal kaynak As Collection, ByVal hedef As Collection, ByVal sicilAnahtarlari As Object, ByVal yedekAnahtarlar As Object, ByRef eklenenSayisi As Long, ByRef atlananSayisi As Long)

    Dim kayit As Variant

    For Each kayit In kaynak
        If KayitBirlesimeEklendi_TekTim(kayit, hedef, sicilAnahtarlari, yedekAnahtarlar) Then
            eklenenSayisi = eklenenSayisi + 1
        Else
            atlananSayisi = atlananSayisi + 1
        End If
    Next kayit

End Sub

Private Function KayitBirlesimeEklendi_TekTim(ByVal kayit As Object, ByVal hedef As Collection, ByVal sicilAnahtarlari As Object, ByVal yedekAnahtarlar As Object) As Boolean

    Dim sicilKey As String
    Dim yedekKey As String

    sicilKey = KayitSicilAnahtari_TekTim(kayit)
    yedekKey = KayitYedekAnahtari_TekTim(kayit)

    If sicilKey <> "" Then
        If sicilAnahtarlari.Exists(sicilKey) Then Exit Function
        sicilAnahtarlari.Add sicilKey, True
    Else
        If yedekAnahtarlar.Exists(yedekKey) Then Exit Function
    End If

    If yedekKey <> "" Then
        If Not yedekAnahtarlar.Exists(yedekKey) Then yedekAnahtarlar.Add yedekKey, True
    End If

    hedef.Add kayit
    KayitBirlesimeEklendi_TekTim = True

End Function

Private Sub KayitKoleksiyonunuOnayliBirlesimeEkle_TekTim(ByVal kaynak As Collection, ByVal hedef As Collection, ByVal sicilAnahtarlari As Object, ByVal yedekAnahtarlar As Object, ByRef eklenenSayisi As Long, ByRef atlananSayisi As Long, ByRef gorevDegisenSayisi As Long, ByRef gorevDegisikligiReddedilenSayisi As Long)

    Dim kayit As Variant
    Dim sicilKey As String
    Dim mevcutIndex As Long
    Dim mevcutKayit As Object

    For Each kayit In kaynak
        sicilKey = KayitSicilAnahtari_TekTim(kayit)

        If sicilKey = "" Then
            If KayitBirlesimeEklendi_TekTim(kayit, hedef, sicilAnahtarlari, yedekAnahtarlar) Then
                eklenenSayisi = eklenenSayisi + 1
            Else
                atlananSayisi = atlananSayisi + 1
            End If
        Else
            mevcutIndex = KayitIndexiniSicileGoreBul_TekTim(hedef, sicilKey)

            If mevcutIndex = 0 Then
                If KayitBirlesimeEklendi_TekTim(kayit, hedef, sicilAnahtarlari, yedekAnahtarlar) Then
                    eklenenSayisi = eklenenSayisi + 1
                Else
                    atlananSayisi = atlananSayisi + 1
                End If
            Else
                Set mevcutKayit = hedef(mevcutIndex)

                If KayitGoreviFarkliMi_TekTim(mevcutKayit, kayit) Then
                    If GorevDegisikligiOnaylandi_TekTim(mevcutKayit, kayit) Then
                        Call KaydiKoleksiyondaDegistir_TekTim(hedef, mevcutIndex, kayit, yedekAnahtarlar)
                        gorevDegisenSayisi = gorevDegisenSayisi + 1
                    Else
                        gorevDegisikligiReddedilenSayisi = gorevDegisikligiReddedilenSayisi + 1
                    End If
                Else
                    atlananSayisi = atlananSayisi + 1
                End If
            End If
        End If
    Next kayit

End Sub

Private Function KayitIndexiniSicileGoreBul_TekTim(ByVal kayitlar As Collection, ByVal sicilKey As String) As Long

    Dim i As Long

    For i = 1 To kayitlar.Count
        If MetinlerEsit_TekTim(KayitSicilAnahtari_TekTim(kayitlar(i)), sicilKey) Then
            KayitIndexiniSicileGoreBul_TekTim = i
            Exit Function
        End If
    Next i

End Function

Private Sub KaydiKoleksiyondaDegistir_TekTim(ByVal kayitlar As Collection, ByVal index As Long, ByVal yeniKayit As Object, ByVal yedekAnahtarlar As Object)

    Dim eskiYedekKey As String
    Dim yeniYedekKey As String

    eskiYedekKey = KayitYedekAnahtari_TekTim(kayitlar(index))
    yeniYedekKey = KayitYedekAnahtari_TekTim(yeniKayit)

    If eskiYedekKey <> "" Then
        If yedekAnahtarlar.Exists(eskiYedekKey) Then yedekAnahtarlar.Remove eskiYedekKey
    End If

    If yeniYedekKey <> "" Then
        If Not yedekAnahtarlar.Exists(yeniYedekKey) Then yedekAnahtarlar.Add yeniYedekKey, True
    End If

    kayitlar.Add yeniKayit, Before:=index
    kayitlar.Remove index + 1

End Sub

Private Function GorevDegisikligiOnaylandi_TekTim(ByVal mevcutKayit As Object, ByVal yeniKayit As Object) As Boolean

    Dim mesaj As String

    mesaj = CStr(yeniKayit("ad")) & " mevcut listede farkli gorevde bulunuyor." & vbCrLf & vbCrLf & _
        "Mevcut: " & KayitGorevMetni_TekTim(mevcutKayit) & vbCrLf & _
        "Yeni: " & KayitGorevMetni_TekTim(yeniKayit) & vbCrLf & vbCrLf & _
        "Gorev degisikligi yapilsin mi?"

    GorevDegisikligiOnaylandi_TekTim = (MsgBox(mesaj, vbQuestion + vbYesNo, "Gorev Degisikligi") = vbYes)

End Function

Private Function KayitGoreviFarkliMi_TekTim(ByVal mevcutKayit As Object, ByVal yeniKayit As Object) As Boolean

    If Not MetinlerEsit_TekTim(CStr(mevcutKayit("grup")), CStr(yeniKayit("grup"))) Then
        KayitGoreviFarkliMi_TekTim = True
    ElseIf Not MetinlerEsit_TekTim(CStr(mevcutKayit("gorev")), CStr(yeniKayit("gorev"))) Then
        KayitGoreviFarkliMi_TekTim = True
    End If

End Function

Private Function KayitGorevMetni_TekTim(ByVal kayit As Object) As String

    Dim gorevMetni As String
    Dim aciklamaMetni As String

    gorevMetni = Trim(CStr(kayit("gorev")))
    aciklamaMetni = Trim(CStr(kayit("aciklama")))

    If gorevMetni = "" Then gorevMetni = "Normal Tim"

    If aciklamaMetni <> "" Then
        KayitGorevMetni_TekTim = gorevMetni & " - " & aciklamaMetni
    Else
        KayitGorevMetni_TekTim = gorevMetni
    End If

End Function

Private Function KayitSicilAnahtari_TekTim(ByVal kayit As Object) As String
    KayitSicilAnahtari_TekTim = NormalizeMetin_TekTim(CStr(kayit("sicil")))
End Function

Private Function KayitYedekAnahtari_TekTim(ByVal kayit As Object) As String
    KayitYedekAnahtari_TekTim = NormalizeMetin_TekTim(CStr(kayit("ad"))) & "|" & _
        NormalizeMetin_TekTim(CStr(kayit("rutbe"))) & "|" & _
        NormalizeMetin_TekTim(CStr(kayit("tim"))) & "|" & _
        NormalizeMetin_TekTim(CStr(kayit("gorev"))) & "|" & _
        NormalizeMetin_TekTim(CStr(kayit("grup"))) & "|" & _
        NormalizeMetin_TekTim(CStr(kayit("aciklama")))
End Function

Private Function PersonelSicilBul_TekTim(ByVal adSoyad As String, ByVal rutbe As String, ByVal timAdi As String) As String

    Dim ws As Worksheet
    Dim sonSatir As Long
    Dim i As Long
    Dim bulunanSicil As String
    Dim adaySayisi As Long

    Set ws = PersonelSayfasiGetir_TekTim(False)
    If ws Is Nothing Then Exit Function

    sonSatir = ws.Cells(ws.Rows.Count, "C").End(xlUp).Row

    For i = 2 To sonSatir
        If DurumAktifMi_TekTim(CStr(ws.Cells(i, "E").Value)) Then
            If MetinlerEsit_TekTim(CStr(ws.Cells(i, "C").Value), adSoyad) Then
                If rutbe = "" Or MetinlerEsit_TekTim(CStr(ws.Cells(i, "B").Value), rutbe) Then
                    If timAdi = "" Or MetinlerEsit_TekTim(CStr(ws.Cells(i, "D").Value), timAdi) Then
                        bulunanSicil = Trim(CStr(ws.Cells(i, "A").Value))
                        adaySayisi = adaySayisi + 1
                    End If
                End If
            End If
        End If
    Next i

    If adaySayisi = 1 Then
        PersonelSicilBul_TekTim = bulunanSicil
        Exit Function
    End If

    If adaySayisi = 0 And timAdi <> "" Then
        PersonelSicilBul_TekTim = PersonelSicilBul_TekTim(adSoyad, rutbe, "")
    End If

End Function

Private Function PersonelTimBul_TekTim(ByVal sicil As String, ByVal adSoyad As String, ByVal rutbe As String, ByVal bolukAdi As String) As String

    Dim ws As Worksheet
    Dim sonSatir As Long
    Dim i As Long
    Dim bulunanTim As String
    Dim adaySayisi As Long
    Dim satirTim As String

    Set ws = PersonelSayfasiGetir_TekTim(False)
    If ws Is Nothing Then Exit Function

    sonSatir = ws.Cells(ws.Rows.Count, "D").End(xlUp).Row

    If Trim(CStr(sicil)) <> "" Then
        For i = 2 To sonSatir
            If MetinlerEsit_TekTim(CStr(ws.Cells(i, "A").Value), sicil) Then
                PersonelTimBul_TekTim = Trim(CStr(ws.Cells(i, "D").Value))
                Exit Function
            End If
        Next i
    End If

    For i = 2 To sonSatir
        If DurumAktifMi_TekTim(CStr(ws.Cells(i, "E").Value)) Then
            If MetinlerEsit_TekTim(CStr(ws.Cells(i, "C").Value), adSoyad) Then
                If rutbe = "" Or MetinlerEsit_TekTim(CStr(ws.Cells(i, "B").Value), rutbe) Then
                    satirTim = Trim(CStr(ws.Cells(i, "D").Value))
                    If bolukAdi = "" Or MetinlerEsit_TekTim(GetBolukAdi_TekTim(satirTim), bolukAdi) Then
                        bulunanTim = satirTim
                        adaySayisi = adaySayisi + 1
                    End If
                End If
            End If
        End If
    Next i

    If adaySayisi = 1 Then
        PersonelTimBul_TekTim = bulunanTim
    End If

End Function

Private Sub GunSayfasiniTemizle_TekTim(ByVal ws As Worksheet)

    On Error Resume Next
    ws.Range("A:" & YARDIMCI_SICIL_KOLONU_TEKTIM).UnMerge
    ws.Range("A:" & YARDIMCI_SICIL_KOLONU_TEKTIM).Clear
    On Error GoTo 0

End Sub

Private Sub GunSayfasiSonKontrol_TekTim(ByVal ws As Worksheet, ByVal kayitlar As Collection, ByVal sonrakiBosSatir As Long)

    Dim sonSatir As Long

    sonSatir = sonrakiBosSatir - 1
    If sonSatir < 3 Then sonSatir = 3

    Call SonBicimVer_TekTim(ws, sonSatir)
    Call GrupRaporlariniKayitlardanYaz_TekTim(kayitlar, ws, sonSatir)

    With ws.PageSetup
        .PrintTitleRows = YAZDIRMA_BASLIK_SATIRLARI_TEKTIM
        .printArea = ws.Range("A1:E" & CStr(sonSatir)).Address
    End With

    ws.Columns(YARDIMCI_GRUP_KOLONU_TEKTIM & ":" & YARDIMCI_SICIL_KOLONU_TEKTIM).Hidden = True

End Sub

Private Function KayitlariSayfayaYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet) As Long

    Dim yazSatir As Long
    Dim yazilanAnahtarlar As Object
    Dim timKey As Variant
    Dim timSirasi As Variant

    yazSatir = 3
    Set yazilanAnahtarlar = CreateObject("Scripting.Dictionary")
    yazilanAnahtarlar.CompareMode = vbTextCompare

    Call DigerGorevKayitlariniYaz_TekTim(kayitlar, ws, GetNobHeyetiMetni_TekTim(), GetNobHeyetiMetni_TekTim(), yazSatir, yazilanAnahtarlar)

    timSirasi = GetSabitTimSirasi_TekTim()
    For Each timKey In timSirasi
        Call DigerTimKayitlariniYaz_TekTim(kayitlar, ws, CStr(timKey), yazSatir, yazilanAnahtarlar)
    Next timKey

    Call OzelGrupKayitlariniYaz_TekTim(kayitlar, ws, yazSatir, yazilanAnahtarlar)
    Call KalanKayitlariYaz_TekTim(kayitlar, ws, yazSatir, yazilanAnahtarlar)

    KayitlariSayfayaYaz_TekTim = yazSatir

End Function

Private Sub DigerGorevKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal hedefGorev As String, ByVal baslik As String, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim ilkSatir As Long
    Dim rutbeSirasi As Variant
    Dim rutbe As Variant

    ilkSatir = yazSatir
    rutbeSirasi = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim(), "")

    For Each rutbe In rutbeSirasi
        Call FiltreliKayitlariYaz_TekTim(kayitlar, ws, "", hedefGorev, CStr(rutbe), (CStr(rutbe) <> ""), "DIGER", yazSatir, yazilanAnahtarlar, True)
    Next rutbe

    If yazSatir > ilkSatir Then
        Call BirlikHucresiOlustur_TekTim(ws, ilkSatir, yazSatir - 1, baslik)
    End If

End Sub

Private Sub DigerTimKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal timAdi As String, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim ilkSatir As Long
    Dim rutbeSirasi As Variant
    Dim rutbe As Variant

    ilkSatir = yazSatir
    rutbeSirasi = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim(), "")

    For Each rutbe In rutbeSirasi
        Call FiltreliKayitlariYaz_TekTim(kayitlar, ws, timAdi, "", CStr(rutbe), (CStr(rutbe) <> ""), "DIGER", yazSatir, yazilanAnahtarlar, False)
    Next rutbe

    If yazSatir > ilkSatir Then
        Call BirlikHucresiOlustur_TekTim(ws, ilkSatir, yazSatir - 1, timAdi)
    End If

End Sub

Private Sub OzelGrupKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim bolukler As Variant
    Dim boluk As Variant
    Dim bolukIlkSatir As Long

    bolukler = Array(GetBirinciBolukMetni_TekTim(), GetIkinciBolukMetni_TekTim(), GetUcuncuBolukMetni_TekTim())

    For Each boluk In bolukler
        bolukIlkSatir = yazSatir

        Call OzelBolukGorevKayitlariniYaz_TekTim(kayitlar, ws, CStr(boluk), GetHazirKitaMetni_TekTim(), "HAZIR_KITA", yazSatir, yazilanAnahtarlar)
        Call OzelBolukGorevKayitlariniYaz_TekTim(kayitlar, ws, CStr(boluk), GetGuluskurMetni_TekTim(), "GULUSKUR", yazSatir, yazilanAnahtarlar)

        If yazSatir > bolukIlkSatir Then
            Call BirlikHucresiOlustur_TekTim(ws, bolukIlkSatir, yazSatir - 1, CStr(boluk))
        End If
    Next boluk

    Call OzelGrupDisiTimKayitlariniYaz_TekTim(kayitlar, ws, yazSatir, yazilanAnahtarlar)

End Sub

Private Sub OzelGrupDisiTimKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim timler As Collection
    Dim eklenenTimler As Object
    Dim kayit As Variant
    Dim timAdi As Variant
    Dim timKey As String
    Dim blokIlkSatir As Long

    Set timler = New Collection
    Set eklenenTimler = CreateObject("Scripting.Dictionary")
    eklenenTimler.CompareMode = vbTextCompare

    For Each kayit In kayitlar
        If MetinlerEsit_TekTim(CStr(kayit("grup")), "HAZIR_KITA") Or MetinlerEsit_TekTim(CStr(kayit("grup")), "GULUSKUR") Then
            timKey = NormalizeMetin_TekTim(CStr(kayit("tim")))
            If timKey <> "" Then
                If GetBolukAdi_TekTim(CStr(kayit("tim"))) = "" And Not BolukAdiMi_TekTim(CStr(kayit("tim"))) Then
                    If Not eklenenTimler.Exists(timKey) Then
                        eklenenTimler.Add timKey, True
                        timler.Add CStr(kayit("tim"))
                    End If
                End If
            End If
        End If
    Next kayit

    For Each timAdi In timler
        blokIlkSatir = yazSatir
        Call OzelTimGrubuKayitlariniYaz_TekTim(kayitlar, ws, CStr(timAdi), GetHazirKitaMetni_TekTim(), "HAZIR_KITA", yazSatir, yazilanAnahtarlar)
        Call OzelTimGrubuKayitlariniYaz_TekTim(kayitlar, ws, CStr(timAdi), GetGuluskurMetni_TekTim(), "GULUSKUR", yazSatir, yazilanAnahtarlar)

        If yazSatir > blokIlkSatir Then
            Call BirlikHucresiOlustur_TekTim(ws, blokIlkSatir, yazSatir - 1, CStr(timAdi))
        End If
    Next timAdi

End Sub

Private Sub OzelTimGrubuKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal timAdi As String, ByVal gorevAdi As String, ByVal grupKodu As String, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim grupIlkSatir As Long
    Dim rutbeSirasi As Variant
    Dim rutbe As Variant

    grupIlkSatir = yazSatir
    rutbeSirasi = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim(), "")

    For Each rutbe In rutbeSirasi
        Call FiltreliKayitlariYaz_TekTim(kayitlar, ws, timAdi, gorevAdi, CStr(rutbe), (CStr(rutbe) <> ""), grupKodu, yazSatir, yazilanAnahtarlar, False)
    Next rutbe

    If yazSatir > grupIlkSatir Then
        Call OzelGorevHucresiOlustur_TekTim(ws, grupIlkSatir, yazSatir - 1, gorevAdi)
    End If

End Sub

Private Sub OzelBolukGorevKayitlariniYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal bolukAdi As String, ByVal gorevAdi As String, ByVal grupKodu As String, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim grupIlkSatir As Long
    Dim rutbeSirasi As Variant
    Dim rutbe As Variant
    Dim timSirasi As Variant
    Dim timKey As Variant

    grupIlkSatir = yazSatir
    rutbeSirasi = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim(), "")
    timSirasi = GetSabitTimSirasi_TekTim()

    For Each timKey In timSirasi
        If MetinlerEsit_TekTim(GetBolukAdi_TekTim(CStr(timKey)), bolukAdi) Then
            For Each rutbe In rutbeSirasi
                Call FiltreliKayitlariYaz_TekTim(kayitlar, ws, CStr(timKey), gorevAdi, CStr(rutbe), (CStr(rutbe) <> ""), grupKodu, yazSatir, yazilanAnahtarlar, False)
            Next rutbe
        End If
    Next timKey

    For Each rutbe In rutbeSirasi
        Call FiltreliKayitlariYaz_TekTim(kayitlar, ws, bolukAdi, gorevAdi, CStr(rutbe), (CStr(rutbe) <> ""), grupKodu, yazSatir, yazilanAnahtarlar, False)
    Next rutbe

    If yazSatir > grupIlkSatir Then
        Call OzelGorevHucresiOlustur_TekTim(ws, grupIlkSatir, yazSatir - 1, gorevAdi)
    End If

End Sub

Private Sub KalanKayitlariYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object)

    Dim kayit As Variant
    Dim ilkSatir As Long

    ilkSatir = yazSatir

    For Each kayit In kayitlar
        If Not yazilanAnahtarlar.Exists(KayitTekilAnahtari_TekTim(kayit)) Then
            Call TekKaydiYaz_TekTim(ws, kayit, yazSatir)
            yazilanAnahtarlar.Add KayitTekilAnahtari_TekTim(kayit), True
        End If
    Next kayit

    If yazSatir > ilkSatir Then
        Call BirlikHucresiOlustur_TekTim(ws, ilkSatir, yazSatir - 1, "ESLESMEYEN / ELLE EKLENEN")
    End If

End Sub

Private Sub FiltreliKayitlariYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal hedefTim As String, ByVal hedefGorev As String, ByVal hedefRutbe As String, ByVal sadeceHedefRutbe As Boolean, ByVal hedefGrup As String, ByRef yazSatir As Long, ByVal yazilanAnahtarlar As Object, ByVal gorevAnaBlok As Boolean)

    Dim kayit As Variant
    Dim anahtar As String

    For Each kayit In kayitlar
        anahtar = KayitTekilAnahtari_TekTim(kayit)
        If Not yazilanAnahtarlar.Exists(anahtar) Then
            If KayitFiltreyeUyar_TekTim(kayit, hedefTim, hedefGorev, hedefRutbe, sadeceHedefRutbe, hedefGrup, gorevAnaBlok) Then
                Call TekKaydiYaz_TekTim(ws, kayit, yazSatir)
                yazilanAnahtarlar.Add anahtar, True
            End If
        End If
    Next kayit

End Sub

Private Function KayitFiltreyeUyar_TekTim(ByVal kayit As Object, ByVal hedefTim As String, ByVal hedefGorev As String, ByVal hedefRutbe As String, ByVal sadeceHedefRutbe As Boolean, ByVal hedefGrup As String, ByVal gorevAnaBlok As Boolean) As Boolean

    If Not MetinlerEsit_TekTim(CStr(kayit("grup")), hedefGrup) Then Exit Function

    If hedefTim <> "" Then
        If Not MetinlerEsit_TekTim(CStr(kayit("tim")), hedefTim) Then Exit Function
    End If

    If gorevAnaBlok Then
        If Not (MetinlerEsit_TekTim(CStr(kayit("gorev")), hedefGorev) Or MetinlerEsit_TekTim(CStr(kayit("tim")), hedefGorev)) Then Exit Function
    ElseIf hedefGorev <> "" Then
        If Not MetinlerEsit_TekTim(CStr(kayit("gorev")), hedefGorev) Then Exit Function
    Else
        If MetinlerEsit_TekTim(CStr(kayit("gorev")), GetNobHeyetiMetni_TekTim()) Then Exit Function
        If MetinlerEsit_TekTim(CStr(kayit("gorev")), GetHazirKitaMetni_TekTim()) Then Exit Function
        If MetinlerEsit_TekTim(CStr(kayit("gorev")), GetGuluskurMetni_TekTim()) Then Exit Function
    End If

    If RutbeYazilsinMi_TekTim(CStr(kayit("rutbe")), hedefRutbe, sadeceHedefRutbe) Then
        KayitFiltreyeUyar_TekTim = True
    End If

End Function

Private Sub TekKaydiYaz_TekTim(ByVal ws As Worksheet, ByVal kayit As Object, ByRef yazSatir As Long)

    ws.Cells(yazSatir, "C").Value = CStr(kayit("rutbe"))
    ws.Cells(yazSatir, "D").Value = CStr(kayit("ad"))

    If MetinlerEsit_TekTim(CStr(kayit("grup")), "DIGER") Then
        ws.Cells(yazSatir, "E").Value = CStr(kayit("aciklama"))
        ws.Cells(yazSatir, "E").HorizontalAlignment = xlLeft
    End If

    ws.Cells(yazSatir, YARDIMCI_GRUP_KOLONU_TEKTIM).Value = CStr(kayit("grup"))
    ws.Cells(yazSatir, YARDIMCI_SICIL_KOLONU_TEKTIM).Value = CStr(kayit("sicil"))
    yazSatir = yazSatir + 1

End Sub

Private Function KayitTekilAnahtari_TekTim(ByVal kayit As Object) As String

    If Trim(CStr(kayit("sicil"))) <> "" Then
        KayitTekilAnahtari_TekTim = "S|" & NormalizeMetin_TekTim(CStr(kayit("sicil")))
    Else
        KayitTekilAnahtari_TekTim = "F|" & KayitYedekAnahtari_TekTim(kayit)
    End If

End Function

Private Sub GrupRaporlariniKayitlardanYaz_TekTim(ByVal kayitlar As Collection, ByVal ws As Worksheet, ByVal sonSatir As Long)

    Dim baslangicSatiri As Long
    Dim hazirKitaRutbeleri As Collection
    Dim guluskurRutbeleri As Collection
    Dim digerRutbeleri As Collection
    Dim maksimumSatirSayisi As Long

    If sonSatir < 3 Then sonSatir = 3

    baslangicSatiri = sonSatir + 2

    Set hazirKitaRutbeleri = GrupRutbeSatirlariniKayitlardanGetir_TekTim(kayitlar, "HAZIR_KITA")
    Set guluskurRutbeleri = GrupRutbeSatirlariniKayitlardanGetir_TekTim(kayitlar, "GULUSKUR")
    Set digerRutbeleri = GrupRutbeSatirlariniKayitlardanGetir_TekTim(kayitlar, "DIGER")

    maksimumSatirSayisi = MaksimumDeger_TekTim( _
        GrupOzetiSatirSayisiGetir_TekTim(hazirKitaRutbeleri), _
        GrupOzetiSatirSayisiGetir_TekTim(guluskurRutbeleri), _
        GrupOzetiSatirSayisiGetir_TekTim(digerRutbeleri))

    If ws.Columns("F").ColumnWidth < 12 Then ws.Columns("F").ColumnWidth = 12
    If ws.Columns("G").ColumnWidth < 12 Then ws.Columns("G").ColumnWidth = 12
    If ws.Columns("H").ColumnWidth < 12 Then ws.Columns("H").ColumnWidth = 12
    If ws.Columns("I").ColumnWidth < 12 Then ws.Columns("I").ColumnWidth = 12

    Call GrupRaporBloguYaz_TekTim(ws, baslangicSatiri, "A", "C", "Hazir Kita", "HAZIR_KITA", YARDIMCI_HAZIR_KITA_OZET_KOLONU_TEKTIM, hazirKitaRutbeleri, maksimumSatirSayisi)
    Call GrupRaporBloguYaz_TekTim(ws, baslangicSatiri, "D", "F", "Guluskur", "GULUSKUR", YARDIMCI_GULUSKUR_OZET_KOLONU_TEKTIM, guluskurRutbeleri, maksimumSatirSayisi)
    Call GrupRaporBloguYaz_TekTim(ws, baslangicSatiri, "G", "I", "Diger Tum Personel", "DIGER", YARDIMCI_DIGER_OZET_KOLONU_TEKTIM, digerRutbeleri, maksimumSatirSayisi)

End Sub

Private Function GrupRutbeSatirlariniKayitlardanGetir_TekTim(ByVal kayitlar As Collection, ByVal grupKodu As String) As Collection

    Dim rutbeDegerleri As Object
    Dim rutbeSirasi As Collection
    Dim satirlar As Collection
    Dim kayit As Variant
    Dim rutbe As String
    Dim rutbeKey As String
    Dim tercihliRutbeler As Variant
    Dim tercihliRutbe As Variant

    Set rutbeDegerleri = CreateObject("Scripting.Dictionary")
    Set rutbeSirasi = New Collection
    Set satirlar = New Collection
    rutbeDegerleri.CompareMode = vbTextCompare

    For Each kayit In kayitlar
        If MetinlerEsit_TekTim(CStr(kayit("grup")), grupKodu) Then
            rutbe = Trim(CStr(kayit("rutbe")))
            If rutbe = "" Then rutbe = "-"
            rutbeKey = NormalizeMetin_TekTim(rutbe)

            If Not rutbeDegerleri.Exists(rutbeKey) Then
                rutbeDegerleri.Add rutbeKey, rutbe
                rutbeSirasi.Add rutbe
            End If
        End If
    Next kayit

    tercihliRutbeler = Array("SB.", "ASB.", "UZM.J.", GetJUzmCvsRutbeMetni_TekTim())

    For Each tercihliRutbe In tercihliRutbeler
        rutbeKey = NormalizeMetin_TekTim(CStr(tercihliRutbe))
        If rutbeDegerleri.Exists(rutbeKey) Then
            satirlar.Add CStr(rutbeDegerleri(rutbeKey))
            rutbeDegerleri.Remove rutbeKey
        End If
    Next tercihliRutbe

    For Each tercihliRutbe In rutbeSirasi
        rutbeKey = NormalizeMetin_TekTim(CStr(tercihliRutbe))
        If rutbeDegerleri.Exists(rutbeKey) Then
            satirlar.Add CStr(rutbeDegerleri(rutbeKey))
            rutbeDegerleri.Remove rutbeKey
        End If
    Next tercihliRutbe

    Set GrupRutbeSatirlariniKayitlardanGetir_TekTim = satirlar

End Function

'================================================================
' AYARLAR SAYFASINDAN BASLIK AL
'================================================================
Private Function GetBaslikMetni_TekTim() As String

    On Error Resume Next
    GetBaslikMetni_TekTim = Trim(CStr(ThisWorkbook.Worksheets("AYARLAR").Range("B1").Value))
    On Error GoTo 0

End Function

'================================================================
' FORMU AC
'================================================================
Public Sub TekTimFormuAc()
    If FormYukluMu_TekTim("frmTekTimSecim") Then Exit Sub

    On Error GoTo FormAcmaHatasi
    frmTekTimSecim.Show vbModeless
    Exit Sub

FormAcmaHatasi:
    MsgBox "frmTekTimSecim acilirken hata olustu: " & Err.Description, vbExclamation, "Form Hatasi"
End Sub

Private Function PersonelSayfasiGetir_TekTim(ByVal mesajGoster As Boolean) As Worksheet

    On Error Resume Next
    Set PersonelSayfasiGetir_TekTim = ThisWorkbook.Worksheets("PERSONEL")
    On Error GoTo 0

    If PersonelSayfasiGetir_TekTim Is Nothing Then
        If mesajGoster Then
            MsgBox "PERSONEL sayfasi bulunamadi. Personel listesi yuklenemedi.", vbExclamation, "Eksik Sayfa"
        End If
    End If

End Function

'================================================================
' YARDIMCI YORDAMLAR
'================================================================
Private Sub PersonelSecimDurumunuSifirla_TekTim()
    mSonTiklananPersonelSatiri_TekTim = -1
End Sub

Private Sub PersonelListesiniHazirla_TekTim(ByVal lst As Object)

    Dim toplamGenislik As Double
    Dim rutbeGenislik As Long
    Dim adSoyadGenislik As Long

    toplamGenislik = lst.Width - 18
    If toplamGenislik < 150 Then toplamGenislik = 150

    rutbeGenislik = CLng(toplamGenislik * 0.3)
    If rutbeGenislik < 58 Then rutbeGenislik = 58

    adSoyadGenislik = CLng(toplamGenislik - rutbeGenislik)
    If adSoyadGenislik < 84 Then adSoyadGenislik = 84

    If rutbeGenislik + adSoyadGenislik > CLng(toplamGenislik) Then
        adSoyadGenislik = CLng(toplamGenislik - rutbeGenislik)
    End If

    With lst
        .Clear
        .ColumnCount = 3
        .ColumnWidths = "0 pt;" & rutbeGenislik & " pt;" & adSoyadGenislik & " pt"
        .MultiSelect = fmMultiSelectMulti
    End With

End Sub

Private Sub SepetListesiniHazirla_TekTim(ByVal lst As Object)

    Dim timGenislik As Long
    Dim gorevGenislik As Long
    Dim rutbeGenislik As Long
    Dim adSoyadGenislik As Long
    Dim aciklamaGenislik As Long
    Dim kullanilabilirGenislik As Long

    kullanilabilirGenislik = CLng(lst.Width - 18)
    If kullanilabilirGenislik < 388 Then kullanilabilirGenislik = 388

    timGenislik = 58
    gorevGenislik = 78
    rutbeGenislik = 54
    adSoyadGenislik = 118
    aciklamaGenislik = kullanilabilirGenislik - timGenislik - gorevGenislik - rutbeGenislik - adSoyadGenislik
    If aciklamaGenislik < 80 Then aciklamaGenislik = 80

    With lst
        .Clear
        .ColumnCount = 6
        .ColumnWidths = "0 pt;" & timGenislik & " pt;" & gorevGenislik & " pt;" & rutbeGenislik & " pt;" & adSoyadGenislik & " pt;" & aciklamaGenislik & " pt"
        .MultiSelect = fmMultiSelectSingle
    End With

End Sub

Private Function SecimBilgileriniHazirla_TekTim(ByVal frm As Object, ByRef seciliTim As String, ByRef seciliGorev As String, ByRef seciliAciklama As String) As Boolean

    seciliTim = Trim(CStr(frm.cmbTim.Value))
    seciliGorev = Trim(CStr(frm.cmbGorev.Value))
    seciliAciklama = SeciliAciklamayiGetir_TekTim(frm)

    If seciliTim = "" Then
        MsgBox "Lutfen once bir tim seciniz.", vbExclamation, "Uyari"
        Exit Function
    End If

    If MetinlerEsit_TekTim(seciliGorev, GetNobHeyetiMetni_TekTim()) Then
        If seciliAciklama = "" Then
            MsgBox "Nob Heyeti icin aciklama seciniz veya Diger Aciklama alanini doldurunuz.", vbExclamation, "Uyari"
            Exit Function
        End If
    End If

    SecimBilgileriniHazirla_TekTim = True

End Function

Private Function TarihMetniniCoz_TekTim(ByVal tarihMetni As String, ByRef tarihDegeri As Date) As Boolean

    Dim parcalar As Variant
    Dim gun As Long
    Dim ay As Long
    Dim yil As Long
    Dim kontrolTarihi As Date

    tarihMetni = Trim$(CStr(tarihMetni))
    tarihMetni = Replace$(tarihMetni, "/", ".")

    If tarihMetni = "" Then Exit Function

    parcalar = Split(tarihMetni, ".")
    If UBound(parcalar) <> 2 Then Exit Function

    If Not IsNumeric(parcalar(0)) Then Exit Function
    If Not IsNumeric(parcalar(1)) Then Exit Function
    If Not IsNumeric(parcalar(2)) Then Exit Function

    gun = CLng(parcalar(0))
    ay = CLng(parcalar(1))
    yil = CLng(parcalar(2))

    If gun <= 0 Or ay <= 0 Or yil <= 0 Then Exit Function

    On Error Resume Next
    kontrolTarihi = DateSerial(yil, ay, gun)
    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    If Day(kontrolTarihi) <> gun Then Exit Function
    If Month(kontrolTarihi) <> ay Then Exit Function
    If Year(kontrolTarihi) <> yil Then Exit Function

    tarihDegeri = kontrolTarihi
    TarihMetniniCoz_TekTim = True

End Function

Private Function SepeteSatirEkle_TekTim(ByVal frm As Object, ByVal personelSatir As Long, ByVal seciliTim As String, ByVal seciliGorev As String, ByVal seciliAciklama As String) As Long

    Dim sonSatir As Long
    Dim mevcutSatir As Long
    Dim mevcutGorev As String
    Dim sicil As String
    Dim rutbe As String
    Dim adSoyad As String

    sicil = Trim(CStr(frm.lstPersonel.List(personelSatir, 0)))
    rutbe = Trim(CStr(frm.lstPersonel.List(personelSatir, 1)))
    adSoyad = Trim(CStr(frm.lstPersonel.List(personelSatir, 2)))

    If sicil = "" Then Exit Function

    mevcutSatir = SepetteSicilSatiriBul_TekTim(frm.lstSecilenler, sicil)
    If mevcutSatir >= 0 Then
        mevcutGorev = Trim(CStr(frm.lstSecilenler.List(mevcutSatir, 2)))

        If GorevlerFarkliMi_TekTim(mevcutGorev, seciliGorev) Then
            If SepetGorevDegisikligiOnaylandi_TekTim(frm.lstSecilenler, mevcutSatir, adSoyad, seciliGorev, seciliAciklama) Then
                Call SepetSatiriniGuncelle_TekTim(frm.lstSecilenler, mevcutSatir, seciliTim, seciliGorev, rutbe, adSoyad, seciliAciklama)
                SepeteSatirEkle_TekTim = SEPET_GOREV_DEGISTI_TEKTIM
            Else
                SepeteSatirEkle_TekTim = SEPET_GOREV_DEGISIKLIGI_REDDEDILDI_TEKTIM
            End If
        Else
            Call SepetSatiriniGuncelle_TekTim(frm.lstSecilenler, mevcutSatir, seciliTim, seciliGorev, rutbe, adSoyad, seciliAciklama)
            SepeteSatirEkle_TekTim = SEPET_ZATEN_VAR_TEKTIM
        End If
        Exit Function
    End If

    frm.lstSecilenler.AddItem sicil
    sonSatir = frm.lstSecilenler.ListCount - 1

    frm.lstSecilenler.List(sonSatir, 1) = seciliTim
    frm.lstSecilenler.List(sonSatir, 2) = seciliGorev
    frm.lstSecilenler.List(sonSatir, 3) = rutbe
    frm.lstSecilenler.List(sonSatir, 4) = adSoyad
    frm.lstSecilenler.List(sonSatir, 5) = seciliAciklama

    SepeteSatirEkle_TekTim = SEPET_EKLENDI_TEKTIM

End Function

Private Sub SepetSatiriniGuncelle_TekTim(ByVal lst As Object, ByVal satir As Long, ByVal timAdi As String, ByVal gorevAdi As String, ByVal rutbe As String, ByVal adSoyad As String, ByVal aciklama As String)

    lst.List(satir, 1) = timAdi
    lst.List(satir, 2) = gorevAdi
    lst.List(satir, 3) = rutbe
    lst.List(satir, 4) = adSoyad
    lst.List(satir, 5) = aciklama

End Sub

Private Function SepetGorevDegisikligiOnaylandi_TekTim(ByVal lst As Object, ByVal mevcutSatir As Long, ByVal yeniAdSoyad As String, ByVal yeniGorev As String, ByVal yeniAciklama As String) As Boolean

    Dim mesaj As String
    Dim adSoyad As String
    Dim mevcutGorevMetni As String
    Dim yeniGorevMetni As String

    adSoyad = Trim(CStr(lst.List(mevcutSatir, 4)))
    If adSoyad = "" Then adSoyad = yeniAdSoyad

    mevcutGorevMetni = SepetGorevMetni_TekTim(CStr(lst.List(mevcutSatir, 2)), CStr(lst.List(mevcutSatir, 5)))
    yeniGorevMetni = SepetGorevMetni_TekTim(yeniGorev, yeniAciklama)

    mesaj = adSoyad & " sepette farkli gorevle bulunuyor." & vbCrLf & vbCrLf & _
        "Mevcut: " & mevcutGorevMetni & vbCrLf & _
        "Yeni: " & yeniGorevMetni & vbCrLf & vbCrLf & _
        "Sepetteki gorevi yeni secimle guncellensin mi?"

    SepetGorevDegisikligiOnaylandi_TekTim = (MsgBox(mesaj, vbQuestion + vbYesNo, "Sepet Gorev Degisikligi") = vbYes)

End Function

Private Function SepetGorevMetni_TekTim(ByVal gorevAdi As String, ByVal aciklama As String) As String

    gorevAdi = Trim(CStr(gorevAdi))
    aciklama = Trim(CStr(aciklama))

    If gorevAdi = "" Then gorevAdi = "Normal Tim"

    If aciklama <> "" Then
        SepetGorevMetni_TekTim = gorevAdi & " - " & aciklama
    Else
        SepetGorevMetni_TekTim = gorevAdi
    End If

End Function

Private Function SepetteSicilSatiriBul_TekTim(ByVal lst As Object, ByVal sicil As String) As Long

    Dim i As Long

    SepetteSicilSatiriBul_TekTim = -1

    For i = 0 To lst.ListCount - 1
        If Not SepetBaslikSatiriMi_TekTim(lst, i) Then
            If MetinlerEsit_TekTim(CStr(lst.List(i, 0)), sicil) Then
            SepetteSicilSatiriBul_TekTim = i
            Exit Function
            End If
        End If
    Next i

End Function

Private Sub SecimAlanlariniTemizle_TekTim(ByVal frm As Object)

    GorevleriYukle_TekTim frm.cmbGorev
    AciklamalariYukle_TekTim AciklamaComboGetir_TekTim(frm)

    If Not AciklamaComboGetir_TekTim(frm) Is Nothing Then
        AciklamaComboGetir_TekTim(frm).ListIndex = 0
    End If

    If Not DigerAciklamaKutusuGetir_TekTim(frm) Is Nothing Then
        DigerAciklamaKutusuGetir_TekTim(frm).Value = ""
    End If

End Sub

Private Function KayitDigerMetni_TekTim(ByVal kayitGorevi As String, ByVal kayitAciklama As String) As String

    kayitGorevi = Trim(CStr(kayitGorevi))
    kayitAciklama = Trim(CStr(kayitAciklama))

    If MetinlerEsit_TekTim(kayitGorevi, GetNobHeyetiMetni_TekTim()) _
        Or MetinlerEsit_TekTim(kayitGorevi, GetHazirKitaMetni_TekTim()) _
        Or MetinlerEsit_TekTim(kayitGorevi, GetGuluskurMetni_TekTim()) Then
        KayitDigerMetni_TekTim = kayitAciklama
    ElseIf kayitGorevi <> "" And kayitAciklama <> "" Then
        KayitDigerMetni_TekTim = kayitGorevi & " - " & kayitAciklama
    ElseIf kayitAciklama <> "" Then
        KayitDigerMetni_TekTim = kayitAciklama
    Else
        KayitDigerMetni_TekTim = kayitGorevi
    End If

End Function


Private Function RutbeYazilsinMi_TekTim(ByVal rutbe As String, ByVal hedefRutbe As String, ByVal sadeceHedefRutbe As Boolean) As Boolean

    If sadeceHedefRutbe Then
        RutbeYazilsinMi_TekTim = MetinlerEsit_TekTim(rutbe, hedefRutbe)
    Else
        RutbeYazilsinMi_TekTim = Not RutbeOncelikliMi_TekTim(rutbe)
    End If

End Function

Private Function RutbeOncelikliMi_TekTim(ByVal rutbe As String) As Boolean

    If MetinlerEsit_TekTim(rutbe, "SB.") Then
        RutbeOncelikliMi_TekTim = True
    ElseIf MetinlerEsit_TekTim(rutbe, "ASB.") Then
        RutbeOncelikliMi_TekTim = True
    ElseIf MetinlerEsit_TekTim(rutbe, "UZM.J.") Then
        RutbeOncelikliMi_TekTim = True
    ElseIf MetinlerEsit_TekTim(rutbe, GetJUzmCvsRutbeMetni_TekTim()) Then
        RutbeOncelikliMi_TekTim = True
    End If

End Function

Private Function GorevlerFarkliMi_TekTim(ByVal gorev1 As String, ByVal gorev2 As String) As Boolean
    GorevlerFarkliMi_TekTim = Not MetinlerEsit_TekTim(Trim(CStr(gorev1)), Trim(CStr(gorev2)))
End Function

Private Function SeciliKayitSayisi_TekTim(ByVal lst As Object) As Long

    Dim i As Long

    For i = 0 To lst.ListCount - 1
        If lst.Selected(i) Then
            SeciliKayitSayisi_TekTim = SeciliKayitSayisi_TekTim + 1
        End If
    Next i

End Function

Private Sub ListeSeciminiTemizle_TekTim(ByVal lst As Object)

    Dim i As Long

    On Error Resume Next

    For i = 0 To lst.ListCount - 1
        lst.Selected(i) = False
    Next i

    lst.ListIndex = -1

    On Error GoTo 0

End Sub

Private Function MetinlerEsit_TekTim(ByVal metin1 As String, ByVal metin2 As String) As Boolean
    MetinlerEsit_TekTim = (NormalizeMetin_TekTim(metin1) = NormalizeMetin_TekTim(metin2))
End Function

Private Function DurumAktifMi_TekTim(ByVal durum As String) As Boolean

    Dim normDurum As String

    normDurum = NormalizeMetin_TekTim(durum)
    If normDurum = "" Then normDurum = "AKTIF"

    DurumAktifMi_TekTim = (normDurum = "AKTIF")

End Function

Private Function NormalizeMetin_TekTim(ByVal deger As String) As String

    Dim sonuc As String

    sonuc = Trim(CStr(deger))
    sonuc = Replace(sonuc, "i", "I")
    sonuc = Replace(sonuc, ChrW(305), "I")
    sonuc = Replace(sonuc, ChrW(304), "I")
    sonuc = UCase$(sonuc)
    sonuc = Replace(sonuc, ChrW(214), "O")
    sonuc = Replace(sonuc, ChrW(220), "U")
    sonuc = Replace(sonuc, ChrW(199), "C")
    sonuc = Replace(sonuc, ChrW(350), "S")
    sonuc = Replace(sonuc, ChrW(286), "G")

    NormalizeMetin_TekTim = sonuc

End Function

Private Function GetHazirKitaMetni_TekTim() As String
    GetHazirKitaMetni_TekTim = "Haz" & ChrW(305) & "r K" & ChrW(305) & "ta"
End Function

Private Function GorevIcinGrupKoduGetir_TekTim(ByVal gorevAdi As String) As String

    If MetinlerEsit_TekTim(gorevAdi, GetHazirKitaMetni_TekTim()) Then
        GorevIcinGrupKoduGetir_TekTim = "HAZIR_KITA"
    ElseIf MetinlerEsit_TekTim(gorevAdi, GetGuluskurMetni_TekTim()) Then
        GorevIcinGrupKoduGetir_TekTim = "GULUSKUR"
    Else
        GorevIcinGrupKoduGetir_TekTim = "DIGER"
    End If

End Function

Private Function GetGuluskurMetni_TekTim() As String
    GetGuluskurMetni_TekTim = "G" & ChrW(252) & "l" & ChrW(252) & ChrW(351) & "k" & ChrW(252) & "r"
End Function

Private Function GetHazirKitaBuyukMetni_TekTim() As String
    GetHazirKitaBuyukMetni_TekTim = "HAZIR KITA"
End Function

Private Function GetGuluskurBuyukMetni_TekTim() As String
    GetGuluskurBuyukMetni_TekTim = "G" & ChrW(220) & "L" & ChrW(220) & ChrW(350) & "K" & ChrW(220) & "R"
End Function

Private Function GetNobHeyetiMetni_TekTim() As String
    GetNobHeyetiMetni_TekTim = "N" & ChrW(246) & "b Heyeti"
End Function

Private Function GetBirinciBolukMetni_TekTim() As String
    GetBirinciBolukMetni_TekTim = "1'" & ChrW(304) & "NC" & ChrW(304) & " BL."
End Function

Private Function GetIkinciBolukMetni_TekTim() As String
    GetIkinciBolukMetni_TekTim = "2'NC" & ChrW(304) & " BL."
End Function

Private Function GetUcuncuBolukMetni_TekTim() As String
    GetUcuncuBolukMetni_TekTim = "3'" & ChrW(220) & "NC" & ChrW(220) & " BL."
End Function

Private Function GetSabitTimSirasi_TekTim() As Variant

    GetSabitTimSirasi_TekTim = Array( _
        "KH", _
        GetBirinciBolukKhMetni_TekTim(), _
        GetBTimiMetni_TekTim(1), _
        GetBTimiMetni_TekTim(2), _
        GetBTimiMetni_TekTim(3), _
        GetIkinciBolukKhMetni_TekTim(), _
        GetBTimiMetni_TekTim(5), _
        GetBTimiMetni_TekTim(6), _
        GetBTimiMetni_TekTim(7), _
        GetUcuncuBolukKhMetni_TekTim(), _
        GetBTimiMetni_TekTim(9), _
        GetBTimiMetni_TekTim(10), _
        GetBTimiMetni_TekTim(11))

End Function

Private Function GetBTimiMetni_TekTim(ByVal timNo As Long) As String
    GetBTimiMetni_TekTim = CStr(timNo) & " B T" & ChrW(304) & "M" & ChrW(304)
End Function

Private Function GetBolukAdi_TekTim(ByVal timAdi As String) As String

    If MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(1)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(2)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(3)) _
        Or MetinlerEsit_TekTim(timAdi, GetBirinciBolukKhMetni_TekTim()) Then
        GetBolukAdi_TekTim = GetBirinciBolukMetni_TekTim()
    ElseIf MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(5)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(6)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(7)) _
        Or MetinlerEsit_TekTim(timAdi, GetIkinciBolukKhMetni_TekTim()) Then
        GetBolukAdi_TekTim = GetIkinciBolukMetni_TekTim()
    ElseIf MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(9)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(10)) _
        Or MetinlerEsit_TekTim(timAdi, GetBTimiMetni_TekTim(11)) _
        Or MetinlerEsit_TekTim(timAdi, GetUcuncuBolukKhMetni_TekTim()) Then
        GetBolukAdi_TekTim = GetUcuncuBolukMetni_TekTim()
    End If

End Function

Private Function BolukAdiMi_TekTim(ByVal deger As String) As Boolean
    BolukAdiMi_TekTim = MetinlerEsit_TekTim(deger, GetBirinciBolukMetni_TekTim()) _
        Or MetinlerEsit_TekTim(deger, GetIkinciBolukMetni_TekTim()) _
        Or MetinlerEsit_TekTim(deger, GetUcuncuBolukMetni_TekTim())
End Function

Private Function OzelGrupKoduMu_TekTim(ByVal grupKodu As String) As Boolean
    OzelGrupKoduMu_TekTim = MetinlerEsit_TekTim(grupKodu, "HAZIR_KITA") _
        Or MetinlerEsit_TekTim(grupKodu, "GULUSKUR")
End Function

Private Sub OzelGorevHucresiOlustur_TekTim(ByVal ws As Worksheet, ByVal ilkSatir As Long, ByVal sonSatir As Long, ByVal gorevAdi As String)

    With ws.Range("E" & ilkSatir & ":E" & sonSatir)
        .Merge
        .Value = GetBuyukOzelGorevMetni_TekTim(gorevAdi)
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        .Orientation = 0
        .WrapText = True
    End With

End Sub

Private Function GetBuyukOzelGorevMetni_TekTim(ByVal gorevAdi As String) As String

    If MetinlerEsit_TekTim(gorevAdi, GetHazirKitaMetni_TekTim()) Then
        GetBuyukOzelGorevMetni_TekTim = GetHazirKitaBuyukMetni_TekTim()
    ElseIf MetinlerEsit_TekTim(gorevAdi, GetGuluskurMetni_TekTim()) Then
        GetBuyukOzelGorevMetni_TekTim = GetGuluskurBuyukMetni_TekTim()
    Else
        GetBuyukOzelGorevMetni_TekTim = UCase$(Trim$(CStr(gorevAdi)))
    End If

End Function

Private Function GetJUzmCvsRutbeMetni_TekTim() As String
    GetJUzmCvsRutbeMetni_TekTim = "J.UZM." & ChrW(199) & "V" & ChrW(350) & "."
End Function

Private Function FormYukluMu_TekTim(ByVal formAdi As String) As Boolean

    Dim acikForm As Object

    On Error Resume Next

    For Each acikForm In VBA.UserForms
        If StrComp(CStr(acikForm.Name), formAdi, vbTextCompare) = 0 Then
            FormYukluMu_TekTim = True
            Exit For
        End If
    Next acikForm

    On Error GoTo 0

End Function

Private Function SayfaVarMi_TekTim(ByVal sayfaAdi As String) As Boolean

    Dim ws As Worksheet

    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(sayfaAdi)
    SayfaVarMi_TekTim = Not ws Is Nothing
    Set ws = Nothing
    On Error GoTo 0

End Function
 

'================================================================
' MODERN TAKVIM ENTEGRASYONU
'================================================================
Public Sub TarihSec_TekTim(ByVal frm As Object)
    Dim res As Variant
    Dim baslangicTarihi As Date
    
    If IsDate(frm.txtTarih.Value) Then
        baslangicTarihi = CDate(frm.txtTarih.Value)
    Else
        baslangicTarihi = Date
    End If
    
    res = mModernCalendar.GetModernDate(baslangicTarihi, False)
    
    If Not IsEmpty(res) Then
        frm.txtTarih.Value = Format(res, "dd.mm.yyyy")
    End If
End Sub

'================================================================
' TAZM?NAT TAK?B? MERKEZ? G?NCELLEME S?STEM? (TAM SENKRON?ZE)
'================================================================
Public Sub TazminatTakibiGuncelle_TekTim(ByVal tarihDegeri As Date)
    Dim wsTakip As Worksheet, wsBugun As Worksheet, wsDun As Worksheet
    Dim sayfaBugun As String, sayfaDun As String
    Dim i As Long, sonSatir As Long, takipSatir As Long
    Dim adSoyad As String, grupKodu As String, aciklamaMetni As String
    Dim gunNo As Long, takipKolon As Long
    
    On Error Resume Next
    Set wsTakip = ThisWorkbook.Worksheets("tazminattakip")
    sayfaBugun = Format(tarihDegeri, "dd.mm")
    sayfaDun = Format(DateAdd("d", -1, tarihDegeri), "dd.mm")
    Set wsBugun = ThisWorkbook.Worksheets(sayfaBugun)
    Set wsDun = ThisWorkbook.Worksheets(sayfaDun)
    On Error GoTo 0
    
    If wsTakip Is Nothing Then Exit Sub
    
    gunNo = Day(tarihDegeri)
    takipKolon = gunNo + 1
    
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    
    ' --- 1. ADIM: ?LG?L? G?N?N S?TUNUNU TAMAMEN TEM?ZLE ---
    sonSatir = wsTakip.Cells(wsTakip.Rows.Count, "A").End(xlUp).Row
    If sonSatir >= 2 Then
        wsTakip.Range(wsTakip.Cells(2, takipKolon), wsTakip.Cells(sonSatir, takipKolon)).ClearContents
    End If
    
    ' --- 2. ADIM: D?NDEN GELEN 2 G?NL?K G?REVLER? YAZ ---
    If Not wsDun Is Nothing Then
        sonSatir = wsDun.Cells(wsDun.Rows.Count, "D").End(xlUp).Row
        For i = 3 To sonSatir
            adSoyad = Trim(CStr(wsDun.Cells(i, "D").Value))
            grupKodu = Trim(CStr(wsDun.Cells(i, YARDIMCI_GRUP_KOLONU_TEKTIM).Value))
            aciklamaMetni = Trim(CStr(wsDun.Cells(i, "E").Value))
            
            ' D?n bu g?revde olan bug?n de X al?r
            If adSoyad <> "" And GorevIkiGunlukMu_TekTim(grupKodu, aciklamaMetni) Then
                takipSatir = TazminatSatirBul_TekTim(wsTakip, adSoyad)
                If takipSatir > 0 Then wsTakip.Cells(takipSatir, takipKolon).Value = "X"
            End If
        Next i
    End If

    ' --- 3. ADIM: BUG?N?N KEND? G?REVLER?N? YAZ ---
    If Not wsBugun Is Nothing Then
        sonSatir = wsBugun.Cells(wsBugun.Rows.Count, "D").End(xlUp).Row
        For i = 3 To sonSatir
            adSoyad = Trim(CStr(wsBugun.Cells(i, "D").Value))
            If adSoyad <> "" And InStr(1, adSoyad, "==") = 0 And InStr(1, adSoyad, "LISTESI") = 0 Then
                takipSatir = TazminatSatirBul_TekTim(wsTakip, adSoyad)
                If takipSatir > 0 Then wsTakip.Cells(takipSatir, takipKolon).Value = "X"
            End If
        Next i
    End If
    
    Application.EnableEvents = True
    Application.ScreenUpdating = True
End Sub

' Hangi g?revlerin 2 g?n s?rece?ini belirleyen yard?mc? fonksiyon
Private Function GorevIkiGunlukMu_TekTim(ByVal grupKodu As String, ByVal aciklama As String) As Boolean
    If grupKodu = "HAZIR_KITA" Or grupKodu = "GULUSKUR" Then
        GorevIkiGunlukMu_TekTim = True
        Exit Function
    End If
    Dim ozelNobetler As Variant, n As Long
    ozelNobetler = Array("Heybet Komutani", "Nob. Sb.", "Garaj Nob.", "TTZA Nob.", "Kule Nob. 1", "Kule Nob. 2")
    For n = LBound(ozelNobetler) To UBound(ozelNobetler)
        If InStr(1, aciklama, ozelNobetler(n), vbTextCompare) > 0 Then
            GorevIkiGunlukMu_TekTim = True
            Exit Function
        End If
    Next n
End Function

' Tazminat sayfas?nda isim arayan yard?mc? fonksiyon
Private Function TazminatSatirBul_TekTim(ByVal ws As Worksheet, ByVal adSoyad As String) As Long
    Dim sonSatir As Long, i As Long
    TazminatSatirBul_TekTim = 0
    sonSatir = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    For i = 2 To sonSatir
        If MetinlerEsit_TekTim(Trim(CStr(ws.Cells(i, "A").Value)), adSoyad) Then
            TazminatSatirBul_TekTim = i
            Exit Function
        End If
    Next i
End Function

Private Function GetBirinciBolukKhMetni_TekTim() As String
    GetBirinciBolukKhMetni_TekTim = "1'" & ChrW(304) & "NC" & ChrW(304) & " BL. KH"
End Function

Private Function GetIkinciBolukKhMetni_TekTim() As String
    GetIkinciBolukKhMetni_TekTim = "2'NC" & ChrW(304) & " BL. KH"
End Function

Private Function GetUcuncuBolukKhMetni_TekTim() As String
    GetUcuncuBolukKhMetni_TekTim = "3'" & ChrW(220) & "NC" & ChrW(220) & " BL. KH"
End Function


