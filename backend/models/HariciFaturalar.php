<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "harici_faturalar".
 *
 * @property int $id
 * @property string|null $fisno
 * @property string|null $__carikartkodu
 * @property string|null $__sourcedepoadi
 * @property string|null $__sourcesubeadi
 * @property string|null $_cdate
 * @property string|null $_date
 * @property string|null $_key
 * @property string|null $_key_scf_carikart
 * @property string|null $_key_scf_irsaliye
 * @property string|null $_key_scf_kasa
 * @property string|null $_key_sis_depo_source
 * @property string|null $_key_sis_sube_source
 * @property string|null $_serial
 * @property string|null $aciklama
 * @property string|null $aciklama1
 * @property string|null $aciklama2
 * @property string|null $aciklama3
 * @property string|null $adsoyad
 * @property float|null $bekleyentutar
 * @property string|null $belgeno
 * @property string|null $belgeno2
 * @property string|null $belgeturu
 * @property string|null $belgeturuack
 * @property string|null $ekalan1
 * @property string|null $ekalan2
 * @property string|null $ekalan3
 * @property string|null $ekalan4
 * @property string|null $ekalan5
 * @property string|null $ekalan6
 * @property string|null $ekleyenkullaniciadi
 * @property float|null $ekmaliyet
 * @property float|null $eslenentutar
 * @property string|null $faturasecretkey
 * @property string|null $firmaadi
 * @property string|null $formbabsgoster
 * @property float|null $gecikmetutari
 * @property string|null $ihracatkey
 * @property string|null $ihracatkodu
 * @property string|null $iptal
 * @property string|null $irsaliyeno
 * @property string|null $istemcitipi
 * @property string|null $ithalatkey
 * @property string|null $ithalatkodu
 * @property float|null $kalantutar_taksit
 * @property string|null $kapanmadurumu
 * @property string|null $karsifirma
 * @property string|null $kasa
 * @property string|null $kasafisno
 * @property string|null $kategori
 * @property string|null $kilitli
 * @property string|null $konsinyeurunfaturasi
 * @property string|null $kullaniciadi
 * @property string|null $kurfarkifaturasi
 * @property string|null $mustahsil_tamam
 * @property float|null $navlun
 * @property float|null $net
 * @property float|null $netdvz
 * @property string|null $odemebelgeturu
 * @property string|null $odemeislemli
 * @property string|null $rafyeri_ekleyenkullanici
 * @property string|null $rafyeri_fisno
 * @property float|null $rafyerimiktar
 * @property string|null $rafyerisevkedildi
 * @property string|null $returnnote
 * @property string|null $saat
 * @property string|null $tarih
 * @property float|null $sabitucret
 * @property string|null $satiselemani
 * @property float|null $toplam
 * @property float|null $toplamara
 * @property float|null $toplamaradvz
 * @property float|null $toplamdvz
 * @property float|null $toplamindirim
 * @property float|null $toplamindirimdvz
 * @property float|null $toplamkdv
 * @property float|null $toplamkdvdvz
 * @property float|null $toplamkdvtevkifati
 * @property float|null $toplamkdvtevkifatidvz
 * @property float|null $toplammasraf
 * @property float|null $toplammasrafdvz
 * @property float|null $toplammiktar
 * @property float|null $toplammiktarrafyerli
 * @property float|null $toplamov
 * @property float|null $toplamovdvz
 * @property float|null $toplamozelmatrah
 * @property float|null $toplamozelmatrahdvz
 * @property string|null $turu
 * @property string|null $turu_kisa
 * @property string|null $turuack
 * @property string|null $turukisa
 * @property string|null $ublodemekodu
 * @property float|null $ucretsizkargolimiti
 * @property string|null $ustislemturuack
 * @property string|null $ustislemturumuh
 * @property string|null $vadegun
 * @property string|null $vergitcno
 * @property string|null $yetkikodu
 */
class HariciFaturalar extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'harici_faturalar';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['fisno', '__carikartkodu', '__sourcedepoadi', '__sourcesubeadi', '_cdate', '_date', '_key', '_key_scf_carikart', '_key_scf_irsaliye', '_key_scf_kasa', '_key_sis_depo_source', '_key_sis_sube_source', '_serial','aciklama', 'aciklama1', 'aciklama2', 'aciklama3', 'adsoyad', 'bekleyentutar', 'belgeno', 'belgeno2', 'belgeturu', 'belgeturuack', 'ekalan1', 'ekalan2', 'ekalan3', 'ekalan4', 'ekalan5', 'ekalan6', 'ekleyenkullaniciadi', 'ekmaliyet', 'eslenentutar', 'faturasecretkey', 'firmaadi', 'formbabsgoster', 'gecikmetutari', 'ihracatkey', 'ihracatkodu', 'iptal', 'irsaliyeno', 'istemcitipi', 'ithalatkey', 'ithalatkodu', 'kalantutar_taksit', 'kapanmadurumu', 'karsifirma', 'kasa', 'kasafisno', 'kategori', 'kilitli', 'konsinyeurunfaturasi', 'kullaniciadi', 'kurfarkifaturasi', 'mustahsil_tamam', 'navlun', 'net', 'netdvz', 'odemebelgeturu', 'odemeislemli', 'rafyeri_ekleyenkullanici', 'rafyeri_fisno', 'rafyerimiktar', 'rafyerisevkedildi', 'returnnote', 'saat', 'tarih', 'sabitucret', 'satiselemani', 'toplam', 'toplamara', 'toplamaradvz', 'toplamdvz', 'toplamindirim', 'toplamindirimdvz', 'toplamkdv', 'toplamkdvdvz', 'toplamkdvtevkifati', 'toplamkdvtevkifatidvz', 'toplammasraf', 'toplammasrafdvz', 'toplammiktar', 'toplammiktarrafyerli', 'toplamov', 'toplamovdvz', 'toplamozelmatrah', 'toplamozelmatrahdvz', 'turu', 'turu_kisa', 'turuack', 'turukisa', 'ublodemekodu', 'ucretsizkargolimiti', 'ustislemturuack', 'ustislemturumuh', 'vadegun', 'vergitcno', 'yetkikodu'], 'default', 'value' => null],
            [['_cdate', '_date', 'saat', 'tarih'], 'safe'],
            [['aciklama', 'aciklama1', 'aciklama2', 'aciklama3', 'faturasecretkey', 'returnnote'], 'string'],
            [['bekleyentutar', 'ekmaliyet', 'eslenentutar', 'gecikmetutari', 'kalantutar_taksit', 'navlun', 'net', 'netdvz', 'rafyerimiktar', 'sabitucret', 'toplam', 'toplamara', 'toplamaradvz', 'toplamdvz', 'toplamindirim', 'toplamindirimdvz', 'toplamkdv', 'toplamkdvdvz', 'toplamkdvtevkifati', 'toplamkdvtevkifatidvz', 'toplammasraf', 'toplammasrafdvz', 'toplammiktar', 'toplammiktarrafyerli', 'toplamov', 'toplamovdvz', 'toplamozelmatrah', 'toplamozelmatrahdvz', 'ucretsizkargolimiti'], 'number'],
            [['fisno', '__carikartkodu', '__sourcedepoadi', '__sourcesubeadi', 'adsoyad', 'belgeno', 'belgeno2', 'belgeturuack', 'ekalan1', 'ekalan2', 'ekalan3', 'ekalan4', 'ekalan5', 'ekalan6', 'ekleyenkullaniciadi', 'firmaadi', 'ihracatkey', 'ihracatkodu', 'irsaliyeno', 'ithalatkey', 'ithalatkodu', 'kasafisno', 'kullaniciadi', 'rafyeri_ekleyenkullanici', 'rafyeri_fisno', 'satiselemani', 'turu_kisa', 'turuack', 'ustislemturuack', 'ustislemturumuh', 'vergitcno', 'yetkikodu'], 'string', 'max' => 255],
            [['_key', '_key_scf_carikart', '_key_scf_irsaliye', '_key_scf_kasa', '_key_sis_depo_source', '_key_sis_sube_source', '_serial', 'belgeturu', 'iptal', 'kapanmadurumu', 'karsifirma', 'kasa', 'odemebelgeturu', 'turu', 'turukisa', 'ublodemekodu', 'vadegun'], 'string', 'max' => 15],
            [['formbabsgoster', 'istemcitipi', 'kategori', 'kilitli', 'konsinyeurunfaturasi', 'kurfarkifaturasi', 'mustahsil_tamam', 'odemeislemli', 'rafyerisevkedildi'], 'string', 'max' => 1],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'fisno' => 'Fisno',
            '__carikartkodu' => 'Carikartkodu',
            '__sourcedepoadi' => 'Sourcedepoadi',
            '__sourcesubeadi' => 'Sourcesubeadi',
            '_cdate' => 'Cdate',
            '_date' => 'Date',
            '_key' => 'Key',
            '_key_scf_carikart' => 'Key Scf Carikart',
            '_key_scf_irsaliye' => 'Key Scf Irsaliye',
            '_key_scf_kasa' => 'Key Scf Kasa',
            '_key_sis_depo_source' => 'Key Sis Depo Source',
            '_key_sis_sube_source' => 'Key Sis Sube Source',
            '_serial' => 'Serial',
            'aciklama' => 'Aciklama',
            'aciklama1' => 'Aciklama1',
            'aciklama2' => 'Aciklama2',
            'aciklama3' => 'Aciklama3',
            'adsoyad' => 'Adsoyad',
            'bekleyentutar' => 'Bekleyentutar',
            'belgeno' => 'Belgeno',
            'belgeno2' => 'Belgeno2',
            'belgeturu' => 'Belgeturu',
            'belgeturuack' => 'Belgeturuack',
            'ekalan1' => 'Ekalan1',
            'ekalan2' => 'Ekalan2',
            'ekalan3' => 'Ekalan3',
            'ekalan4' => 'Ekalan4',
            'ekalan5' => 'Ekalan5',
            'ekalan6' => 'Ekalan6',
            'ekleyenkullaniciadi' => 'Ekleyenkullaniciadi',
            'ekmaliyet' => 'Ekmaliyet',
            'eslenentutar' => 'Eslenentutar',
            'faturasecretkey' => 'Faturasecretkey',
            'firmaadi' => 'Firmaadi',
            'formbabsgoster' => 'Formbabsgoster',
            'gecikmetutari' => 'Gecikmetutari',
            'ihracatkey' => 'Ihracatkey',
            'ihracatkodu' => 'Ihracatkodu',
            'iptal' => 'Iptal',
            'irsaliyeno' => 'Irsaliyeno',
            'istemcitipi' => 'Istemcitipi',
            'ithalatkey' => 'Ithalatkey',
            'ithalatkodu' => 'Ithalatkodu',
            'kalantutar_taksit' => 'Kalantutar Taksit',
            'kapanmadurumu' => 'Kapanmadurumu',
            'karsifirma' => 'Karsifirma',
            'kasa' => 'Kasa',
            'kasafisno' => 'Kasafisno',
            'kategori' => 'Kategori',
            'kilitli' => 'Kilitli',
            'konsinyeurunfaturasi' => 'Konsinyeurunfaturasi',
            'kullaniciadi' => 'Kullaniciadi',
            'kurfarkifaturasi' => 'Kurfarkifaturasi',
            'mustahsil_tamam' => 'Mustahsil Tamam',
            'navlun' => 'Navlun',
            'net' => 'Net',
            'netdvz' => 'Netdvz',
            'odemebelgeturu' => 'Odemebelgeturu',
            'odemeislemli' => 'Odemeislemli',
            'rafyeri_ekleyenkullanici' => 'Rafyeri Ekleyenkullanici',
            'rafyeri_fisno' => 'Rafyeri Fisno',
            'rafyerimiktar' => 'Rafyerimiktar',
            'rafyerisevkedildi' => 'Rafyerisevkedildi',
            'returnnote' => 'Returnnote',
            'saat' => 'Saat',
            'tarih' => 'Tarih',
            'sabitucret' => 'Sabitucret',
            'satiselemani' => 'Satiselemani',
            'toplam' => 'Toplam',
            'toplamara' => 'Toplamara',
            'toplamaradvz' => 'Toplamaradvz',
            'toplamdvz' => 'Toplamdvz',
            'toplamindirim' => 'Toplamindirim',
            'toplamindirimdvz' => 'Toplamindirimdvz',
            'toplamkdv' => 'Toplamkdv',
            'toplamkdvdvz' => 'Toplamkdvdvz',
            'toplamkdvtevkifati' => 'Toplamkdvtevkifati',
            'toplamkdvtevkifatidvz' => 'Toplamkdvtevkifatidvz',
            'toplammasraf' => 'Toplammasraf',
            'toplammasrafdvz' => 'Toplammasrafdvz',
            'toplammiktar' => 'Toplammiktar',
            'toplammiktarrafyerli' => 'Toplammiktarrafyerli',
            'toplamov' => 'Toplamov',
            'toplamovdvz' => 'Toplamovdvz',
            'toplamozelmatrah' => 'Toplamozelmatrah',
            'toplamozelmatrahdvz' => 'Toplamozelmatrahdvz',
            'turu' => 'Turu',
            'turu_kisa' => 'Turu Kisa',
            'turuack' => 'Turuack',
            'turukisa' => 'Turukisa',
            'ublodemekodu' => 'Ublodemekodu',
            'ucretsizkargolimiti' => 'Ucretsizkargolimiti',
            'ustislemturuack' => 'Ustislemturuack',
            'ustislemturumuh' => 'Ustislemturumuh',
            'vadegun' => 'Vadegun',
            'vergitcno' => 'Vergitcno',
            'yetkikodu' => 'Yetkikodu',
        ];
    }

    /**
     * Gets query for [[HariciFaturaKalem]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getKalemler()
    {
        return $this->hasMany(HariciFaturaKalem::class, ['_key_scf_fatura' => '_key']);
    }

}
