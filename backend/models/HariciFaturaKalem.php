<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "harici_fatura_kalem".
 *
 * @property int $id
 * @property string|null $_cdate
 * @property string|null $_date
 * @property string|null $_key
 * @property string|null $_key_kalemturu
 * @property string|null $_key_scf_carikart
 * @property string|null $_key_scf_fatura
 * @property string|null $_key_scf_irsaliye_kalemi
 * @property string|null $_key_scf_kalem_birimleri
 * @property string|null $_key_sis_depo_source
 * @property string|null $_key_sis_doviz
 * @property string|null $_key_sis_sube_source
 * @property string|null $_serial
 * @property string|null $unvan
 * @property string|null $aciklama
 * @property float|null $anamiktar
 * @property string|null $baglifiyatfarkikalemifaturano
 * @property string|null $baglifiyatkarti
 * @property int|null $barkodokutmasayisi
 * @property string|null $belgeno
 * @property string|null $belgeno2
 * @property float|null $birimfiyati
 * @property string|null $carikodu
 * @property float|null $dagilimkalanmiktar
 * @property float|null $dagilimkalantutar
 * @property string|null $depo
 * @property string|null $ekleyenkullaniciadi
 * @property string|null $ekmalzemekalemi
 * @property string|null $fatanabirimi
 * @property string|null $fatbirimi
 * @property string|null $fatbirimkey
 * @property string|null $faturaikincibirimi
 * @property float|null $faturaikincibirimmiktar
 * @property string|null $fisno
 * @property string|null $gtipno
 * @property float|null $iadeanamiktar
 * @property float|null $iadebirimmaliyeti
 * @property string|null $iadefaturano
 * @property string|null $iadefaturatarih
 * @property string|null $iadefisno
 * @property float|null $iadekalanmiktar
 * @property string|null $ihracatkodu
 * @property float|null $indirim1
 * @property float|null $indirim2
 * @property float|null $indirim3
 * @property float|null $indirim4
 * @property float|null $indirim5
 * @property float|null $indirimtoplam
 * @property float|null $indirimtutari
 * @property string|null $iptal
 * @property string|null $irsaliyeno
 * @property string|null $irsaliyetarih
 * @property string|null $istemcitipi
 * @property string|null $ithalatkodu
 * @property float|null $kalanhizmetmaliyettutari
 * @property string|null $kalemdovizi
 * @property string|null $kalemturu
 * @property string|null $kartaciklama
 * @property string|null $kartkodu
 * @property string|null $kartozelkodu1
 * @property string|null $kartozelkodu2
 * @property string|null $kartozelkodu3
 * @property string|null $kartozelkodu4
 * @property string|null $kartozelkodu5
 * @property string|null $kartozelkodu6
 * @property string|null $kartozelkodu7
 * @property string|null $kartozelkodu8
 * @property string|null $kartozelkodu9
 * @property string|null $kartozelkodu10
 * @property string|null $kartozelkodu11
 * @property string|null $kasa
 * @property string|null $kasakartkodu
 * @property float|null $kdv
 * @property string|null $kdvdurumu
 * @property float|null $kdvharictutar
 * @property string|null $kdvtevkifatkodu
 * @property float|null $kdvtutari
 * @property string|null $kullaniciadi
 * @property string|null $maliyet_fatura_key
 * @property string|null $maliyet_fatura_no
 * @property string|null $maliyet_key
 * @property string|null $maliyet_kodu
 * @property float|null $maliyetlendirilenhizmettutari
 * @property string|null $masrafmerkezikodu
 * @property string|null $masrafmerkezikodu_kalem
 * @property string|null $mh
 * @property float|null $miktar
 * @property string|null $muhasebelesme
 * @property string|null $note
 * @property string|null $note2
 * @property string|null $odemeplani
 * @property string|null $ovmanuel
 * @property float|null $ovorantutari
 * @property float|null $ovtoplamtutari
 * @property float|null $ovtutartutari
 * @property float|null $ovtutartutari2
 * @property float|null $ozelalan1
 * @property float|null $ozelalan2
 * @property float|null $ozelalan3
 * @property float|null $ozelalan4
 * @property float|null $ozelalan5
 * @property string|null $ozelalanf
 * @property float|null $ozelmatrah
 * @property int|null $paketlemekapadedi
 * @property string|null $paketlemekapno
 * @property string|null $paketlemetipkodu
 * @property string|null $proje_kodu_aciklama
 * @property string|null $promosyonkalemid
 * @property string|null $saat
 * @property string|null $satiselemani
 * @property string|null $siparisno
 * @property string|null $siparistarih
 * @property float|null $sonbirimfiyati
 * @property float|null $sonbirimfiyatifisdovizi
 * @property string|null $sonokutulanbarkod
 * @property float|null $sontutaryerel
 * @property float|null $stopajyuzde
 * @property string|null $sube
 * @property string|null $tarih
 * @property float|null $toplambrutagirlik
 * @property float|null $toplambruthacim
 * @property float|null $toplamkdvharictutar
 * @property float|null $toplamkdvtutari
 * @property float|null $toplamnetagirlik
 * @property float|null $toplamnethacim
 * @property float|null $toplamtutar
 * @property float|null $toplamtutarsatirdovizi
 * @property string|null $turu
 * @property string|null $turuack
 * @property float|null $tutari
 * @property float|null $tutarisatirdovizi
 * @property float|null $yerelbirimfiyati
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class HariciFaturaKalem extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'harici_fatura_kalem';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['_cdate', '_date', '_key', '_key_kalemturu', '_key_scf_carikart', '_key_scf_fatura', '_key_scf_irsaliye_kalemi', '_key_scf_kalem_birimleri', '_key_sis_depo_source', '_key_sis_doviz', '_key_sis_sube_source', '_serial', 'unvan', 'aciklama', 'anamiktar', 'baglifiyatfarkikalemifaturano', 'baglifiyatkarti', 'barkodokutmasayisi', 'belgeno', 'belgeno2', 'birimfiyati', 'carikodu', 'dagilimkalanmiktar', 'dagilimkalantutar', 'depo', 'ekleyenkullaniciadi', 'ekmalzemekalemi', 'fatanabirimi', 'fatbirimi', 'fatbirimkey', 'faturaikincibirimi', 'faturaikincibirimmiktar', 'fisno', 'gtipno', 'iadeanamiktar', 'iadebirimmaliyeti', 'iadefaturano', 'iadefaturatarih', 'iadefisno', 'iadekalanmiktar', 'ihracatkodu', 'indirim1', 'indirim2', 'indirim3', 'indirim4', 'indirim5', 'indirimtoplam', 'indirimtutari', 'iptal', 'irsaliyeno', 'irsaliyetarih', 'istemcitipi', 'ithalatkodu', 'kalanhizmetmaliyettutari', 'kalemdovizi', 'kalemturu', 'kartaciklama', 'kartkodu', 'kartozelkodu1', 'kartozelkodu2', 'kartozelkodu3', 'kartozelkodu4', 'kartozelkodu5', 'kartozelkodu6', 'kartozelkodu7', 'kartozelkodu8', 'kartozelkodu9', 'kartozelkodu10', 'kartozelkodu11', 'kasa', 'kasakartkodu', 'kdv', 'kdvdurumu', 'kdvharictutar', 'kdvtevkifatkodu', 'kdvtutari', 'kullaniciadi', 'maliyet_fatura_key', 'maliyet_fatura_no', 'maliyet_key', 'maliyet_kodu', 'maliyetlendirilenhizmettutari', 'masrafmerkezikodu', 'masrafmerkezikodu_kalem', 'mh', 'miktar', 'muhasebelesme', 'note', 'note2', 'odemeplani', 'ovmanuel', 'ovorantutari', 'ovtoplamtutari', 'ovtutartutari', 'ovtutartutari2', 'ozelalan1', 'ozelalan2', 'ozelalan3', 'ozelalan4', 'ozelalan5', 'ozelalanf', 'ozelmatrah', 'paketlemekapadedi', 'paketlemekapno', 'paketlemetipkodu', 'proje_kodu_aciklama', 'promosyonkalemid', 'saat', 'satiselemani', 'siparisno', 'siparistarih', 'sonbirimfiyati', 'sonbirimfiyatifisdovizi', 'sonokutulanbarkod', 'sontutaryerel', 'stopajyuzde', 'sube', 'tarih', 'toplambrutagirlik', 'toplambruthacim', 'toplamkdvharictutar', 'toplamkdvtutari', 'toplamnetagirlik', 'toplamnethacim', 'toplamtutar', 'toplamtutarsatirdovizi', 'turu', 'turuack', 'tutari', 'tutarisatirdovizi', 'yerelbirimfiyati', 'created_at', 'updated_at'], 'default', 'value' => null],
            [['_cdate', '_date', 'iadefaturatarih', 'irsaliyetarih', 'saat', 'siparistarih', 'tarih', 'created_at', 'updated_at'], 'safe'],
            [['anamiktar', 'birimfiyati', 'dagilimkalanmiktar', 'dagilimkalantutar', 'faturaikincibirimmiktar', 'iadeanamiktar', 'iadebirimmaliyeti', 'iadekalanmiktar', 'indirim1', 'indirim2', 'indirim3', 'indirim4', 'indirim5', 'indirimtoplam', 'indirimtutari', 'kalanhizmetmaliyettutari', 'kdv', 'kdvharictutar', 'kdvtutari', 'maliyetlendirilenhizmettutari', 'miktar', 'ovorantutari', 'ovtoplamtutari', 'ovtutartutari', 'ovtutartutari2', 'ozelalan1', 'ozelalan2', 'ozelalan3', 'ozelalan4', 'ozelalan5', 'ozelmatrah', 'sonbirimfiyati', 'sonbirimfiyatifisdovizi', 'sontutaryerel', 'stopajyuzde', 'toplambrutagirlik', 'toplambruthacim', 'toplamkdvharictutar', 'toplamkdvtutari', 'toplamnetagirlik', 'toplamnethacim', 'toplamtutar', 'toplamtutarsatirdovizi', 'tutari', 'tutarisatirdovizi', 'yerelbirimfiyati'], 'number'],
            [['barkodokutmasayisi', 'paketlemekapadedi'], 'integer'],
            [['aciklama', 'kartaciklama', 'note', 'note2', 'proje_kodu_aciklama'], 'string'],
            [['_key', '_key_kalemturu', '_key_scf_carikart', '_key_scf_fatura', '_key_scf_irsaliye_kalemi', '_key_scf_kalem_birimleri', '_key_sis_depo_source', '_key_sis_doviz', '_key_sis_sube_source', '_serial', 'fatbirimkey', 'kasa', 'maliyet_fatura_key', 'maliyet_key', 'muhasebelesme', 'paketlemetipkodu', 'turu'], 'string', 'max' => 15],
            [['baglifiyatfarkikalemifaturano', 'baglifiyatkarti', 'belgeno', 'belgeno2', 'carikodu', 'fisno', 'gtipno', 'iadefaturano', 'iadefisno', 'ihracatkodu', 'ithalatkodu', 'kalemturu', 'kartkodu', 'kartozelkodu1', 'kartozelkodu2', 'kartozelkodu3', 'kartozelkodu4', 'kartozelkodu5', 'kartozelkodu6', 'kartozelkodu7', 'kartozelkodu8', 'kartozelkodu9', 'kartozelkodu10', 'kartozelkodu11', 'kasakartkodu', 'kdvtevkifatkodu', 'kullaniciadi', 'maliyet_fatura_no', 'maliyet_kodu', 'masrafmerkezikodu', 'masrafmerkezikodu_kalem', 'odemeplani', 'ozelalanf', 'paketlemekapno', 'promosyonkalemid', 'siparisno', 'sonokutulanbarkod'], 'string', 'max' => 255],
            [['unvan'], 'string', 'max' => 255],
            [['depo', 'ekleyenkullaniciadi', 'satiselemani', 'sube', 'turuack'], 'string', 'max' => 100],
            [['ekmalzemekalemi', 'iptal', 'istemcitipi', 'kdvdurumu', 'mh', 'ovmanuel'], 'string', 'max' => 1],
            [['fatanabirimi', 'fatbirimi', 'faturaikincibirimi'], 'string', 'max' => 20],
            [['kalemdovizi'], 'string', 'max' => 10],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            '_cdate' => 'Cdate',
            '_date' => 'Date',
            '_key' => 'Key',
            '_key_kalemturu' => 'Key Kalemturu',
            '_key_scf_carikart' => 'Key Scf Carikart',
            '_key_scf_fatura' => 'Key Scf Fatura',
            '_key_scf_irsaliye_kalemi' => 'Key Scf Irsaliye Kalemi',
            '_key_scf_kalem_birimleri' => 'Key Scf Kalem Birimleri',
            '_key_sis_depo_source' => 'Key Sis Depo Source',
            '_key_sis_doviz' => 'Key Sis Doviz',
            '_key_sis_sube_source' => 'Key Sis Sube Source',
            '_serial' => 'Serial',
            'unvan' => 'Unvan',
            'aciklama' => 'Aciklama',
            'anamiktar' => 'Anamiktar',
            'baglifiyatfarkikalemifaturano' => 'Baglifiyatfarkikalemifaturano',
            'baglifiyatkarti' => 'Baglifiyatkarti',
            'barkodokutmasayisi' => 'Barkodokutmasayisi',
            'belgeno' => 'Belgeno',
            'belgeno2' => 'Belgeno2',
            'birimfiyati' => 'Birimfiyati',
            'carikodu' => 'Carikodu',
            'dagilimkalanmiktar' => 'Dagilimkalanmiktar',
            'dagilimkalantutar' => 'Dagilimkalantutar',
            'depo' => 'Depo',
            'ekleyenkullaniciadi' => 'Ekleyenkullaniciadi',
            'ekmalzemekalemi' => 'Ekmalzemekalemi',
            'fatanabirimi' => 'Fatanabirimi',
            'fatbirimi' => 'Fatbirimi',
            'fatbirimkey' => 'Fatbirimkey',
            'faturaikincibirimi' => 'Faturaikincibirimi',
            'faturaikincibirimmiktar' => 'Faturaikincibirimmiktar',
            'fisno' => 'Fisno',
            'gtipno' => 'Gtipno',
            'iadeanamiktar' => 'Iadeanamiktar',
            'iadebirimmaliyeti' => 'Iadebirimmaliyeti',
            'iadefaturano' => 'Iadefaturano',
            'iadefaturatarih' => 'Iadefaturatarih',
            'iadefisno' => 'Iadefisno',
            'iadekalanmiktar' => 'Iadekalanmiktar',
            'ihracatkodu' => 'Ihracatkodu',
            'indirim1' => 'Indirim1',
            'indirim2' => 'Indirim2',
            'indirim3' => 'Indirim3',
            'indirim4' => 'Indirim4',
            'indirim5' => 'Indirim5',
            'indirimtoplam' => 'Indirimtoplam',
            'indirimtutari' => 'Indirimtutari',
            'iptal' => 'Iptal',
            'irsaliyeno' => 'Irsaliyeno',
            'irsaliyetarih' => 'Irsaliyetarih',
            'istemcitipi' => 'Istemcitipi',
            'ithalatkodu' => 'Ithalatkodu',
            'kalanhizmetmaliyettutari' => 'Kalanhizmetmaliyettutari',
            'kalemdovizi' => 'Kalemdovizi',
            'kalemturu' => 'Kalemturu',
            'kartaciklama' => 'Kartaciklama',
            'kartkodu' => 'Kartkodu',
            'kartozelkodu1' => 'Kartozelkodu1',
            'kartozelkodu2' => 'Kartozelkodu2',
            'kartozelkodu3' => 'Kartozelkodu3',
            'kartozelkodu4' => 'Kartozelkodu4',
            'kartozelkodu5' => 'Kartozelkodu5',
            'kartozelkodu6' => 'Kartozelkodu6',
            'kartozelkodu7' => 'Kartozelkodu7',
            'kartozelkodu8' => 'Kartozelkodu8',
            'kartozelkodu9' => 'Kartozelkodu9',
            'kartozelkodu10' => 'Kartozelkodu10',
            'kartozelkodu11' => 'Kartozelkodu11',
            'kasa' => 'Kasa',
            'kasakartkodu' => 'Kasakartkodu',
            'kdv' => 'Kdv',
            'kdvdurumu' => 'Kdvdurumu',
            'kdvharictutar' => 'Kdvharictutar',
            'kdvtevkifatkodu' => 'Kdvtevkifatkodu',
            'kdvtutari' => 'Kdvtutari',
            'kullaniciadi' => 'Kullaniciadi',
            'maliyet_fatura_key' => 'Maliyet Fatura Key',
            'maliyet_fatura_no' => 'Maliyet Fatura No',
            'maliyet_key' => 'Maliyet Key',
            'maliyet_kodu' => 'Maliyet Kodu',
            'maliyetlendirilenhizmettutari' => 'Maliyetlendirilenhizmettutari',
            'masrafmerkezikodu' => 'Masrafmerkezikodu',
            'masrafmerkezikodu_kalem' => 'Masrafmerkezikodu Kalem',
            'mh' => 'Mh',
            'miktar' => 'Miktar',
            'muhasebelesme' => 'Muhasebelesme',
            'note' => 'Note',
            'note2' => 'Note2',
            'odemeplani' => 'Odemeplani',
            'ovmanuel' => 'Ovmanuel',
            'ovorantutari' => 'Ovorantutari',
            'ovtoplamtutari' => 'Ovtoplamtutari',
            'ovtutartutari' => 'Ovtutartutari',
            'ovtutartutari2' => 'Ovtutartutari2',
            'ozelalan1' => 'Ozelalan1',
            'ozelalan2' => 'Ozelalan2',
            'ozelalan3' => 'Ozelalan3',
            'ozelalan4' => 'Ozelalan4',
            'ozelalan5' => 'Ozelalan5',
            'ozelalanf' => 'Ozelalanf',
            'ozelmatrah' => 'Ozelmatrah',
            'paketlemekapadedi' => 'Paketlemekapadedi',
            'paketlemekapno' => 'Paketlemekapno',
            'paketlemetipkodu' => 'Paketlemetipkodu',
            'proje_kodu_aciklama' => 'Proje Kodu Aciklama',
            'promosyonkalemid' => 'Promosyonkalemid',
            'saat' => 'Saat',
            'satiselemani' => 'Satiselemani',
            'siparisno' => 'Siparisno',
            'siparistarih' => 'Siparistarih',
            'sonbirimfiyati' => 'Sonbirimfiyati',
            'sonbirimfiyatifisdovizi' => 'Sonbirimfiyatifisdovizi',
            'sonokutulanbarkod' => 'Sonokutulanbarkod',
            'sontutaryerel' => 'Sontutaryerel',
            'stopajyuzde' => 'Stopajyuzde',
            'sube' => 'Sube',
            'tarih' => 'Tarih',
            'toplambrutagirlik' => 'Toplambrutagirlik',
            'toplambruthacim' => 'Toplambruthacim',
            'toplamkdvharictutar' => 'Toplamkdvharictutar',
            'toplamkdvtutari' => 'Toplamkdvtutari',
            'toplamnetagirlik' => 'Toplamnetagirlik',
            'toplamnethacim' => 'Toplamnethacim',
            'toplamtutar' => 'Toplamtutar',
            'toplamtutarsatirdovizi' => 'Toplamtutarsatirdovizi',
            'turu' => 'Turu',
            'turuack' => 'Turuack',
            'tutari' => 'Tutari',
            'tutarisatirdovizi' => 'Tutarisatirdovizi',
            'yerelbirimfiyati' => 'Yerelbirimfiyati',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    /**
     * Gets query for [[HariciFaturalar]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getFatura()
    {
        return $this->hasOne(HariciFaturalar::class, ['_key' => '_key_scf_fatura']);
    }

}
