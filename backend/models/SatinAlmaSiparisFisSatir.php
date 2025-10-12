<?php

namespace app\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;

/**
 * This is the model class for table "satin_alma_siparis_fis_satir".
 *
 * @property int $id
 * @property int|null $siparis_id
 * @property int|null $urun_id
 * @property string|null $StokKodu
 * @property float|null $miktar
 * @property string|null $tedarikci_kodu
 * @property int|null $tedarikci_fis_id
 * @property string|null $invoice
 * @property string|null $birim
 * @property int|null $layer
 * @property string|null $notes
 * @property float|null $son_7_gun
 * @property float|null $one_week
 * @property float|null $two_week
 * @property float|null $three_week
 * @property float|null $one_month
 * @property float|null $two_months
 * @property float|null $three_months
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property int|null $status
 * @property int|null $good_received
 * @property float|null $retro
 * @property float|null $cost
 * @property float|null $BirimFiyat
 * @property float|null $ToplamTutar
 * @property string|null $po_id
 * @property int|null $type
 * @property int|null $aylık_satis_tahmin
 *
 * @property SatinAlmaSiparisFis $siparis
 * @property TedarikciSiparisFis $tedarikciFis
 * @property Urunler $urun
 * @property Tedarikci $tedarikci
 */
class SatinAlmaSiparisFisSatir extends \yii\db\ActiveRecord
{
    public $price;
    public $stokKodu;
    public $urunAdi;
    public $markaAdi;
    public $urunLayer;
    public $urunPallet;
    public $salesVelocity;
    public $suggest;
    
    // Branch miktarları için virtual attributelar
    private $_branchQuantities = [];
    // Branch bazlı geçen ay satışları için virtual attributelar
    private $_branchOneMonthSales = [];
    // Branch bazlı sales velocity için virtual attributelar
    private $_branchVelocities = [];
    // Branch bazlı birim adları için virtual attributelar
    private $_branchUnits = [];

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satin_alma_siparis_fis_satir';
    }

    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'createdAtAttribute' => 'created_at',
                'updatedAtAttribute' => 'updated_at',
                'value' => new Expression('NOW()'),
            ],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['type'], 'default', 'value' => 0],
            [['siparis_id', 'urun_id', 'tedarikci_fis_id', 'layer', 'status', 'good_received', 'type', 'aylık_satis_tahmin'], 'integer'],
            [['miktar', 'son_7_gun', 'one_week', 'two_week', 'three_week', 'one_month', 'two_months', 'three_months', 'retro', 'cost', 'BirimFiyat', 'ToplamTutar'], 'number'],
            [['created_at', 'updated_at'], 'safe'],
            [['StokKodu', 'tedarikci_kodu'], 'string', 'max' => 50],
            [['invoice'], 'string', 'max' => 45],
            [['po_id'], 'string', 'max' => 15],
            [['birim'], 'string', 'max' => 10],
            [['notes'], 'string', 'max' => 255],
            [['siparis_id'], 'exist', 'skipOnError' => true, 'targetClass' => SatinAlmaSiparisFis::class, 'targetAttribute' => ['siparis_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'siparis_id' => 'Siparis ID',
            'urun_id' => 'Product ID',
            'StokKodu' => 'Product Code',
            'stokKodu' => 'Stock Code',
            'urunAdi' => 'Product Name',
            'markaAdi' => 'Brand',
            'miktar' => 'Quantity',
            'tedarikci_kodu' => 'Supplier Code',
            'tedarikci_fis_id' => 'Supplier Receipt ID',
            'invoice' => 'Invoice',
            'birim' => 'Unit',
            'layer' => 'Layer',
            'urunLayer' => 'Layer',
            'urunPallet' => 'Pallet',
            'notes' => 'Notes',
            'son_7_gun' => 'Last 7 Days',
            'one_week' => '1 Week',
            'two_week' => '2 Weeks',
            'three_week' => '3 Weeks',
            'one_month' => '1 Month',
            'two_months' => '2 Months',
            'three_months' => '3 Months',
            'price' => 'Price',
            'salesVelocity' => 'Sales Velocity',
            'suggest' => 'Suggest',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'status' => 'Status',
            'good_received' => 'Good Received',
            'retro' => 'Retro',
            'cost' => 'Cost',
            'BirimFiyat' => 'Unit Price',
            'ToplamTutar' => 'Total Amount',
            'po_id' => 'PO ID',
            'type' => 'Type',
            'aylık_satis_tahmin' => 'Monthly Forecast',
        ];
    }

    /**
     * Gets query for [[Siparis]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSiparis()
    {
        return $this->hasOne(SatinAlmaSiparisFis::class, ['id' => 'siparis_id']);
    }

    /**
     * Gets query for [[TedarikciFis]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getTedarikciFis()
    {
        return $this->hasOne(TedarikciSiparisFis::class, ['id' => 'tedarikci_fis_id']);
    }

    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['UrunId' => 'urun_id'])->andWhere(['urunler.aktif' => 1]);
    }

    public function getTedarikci()
    {
        return $this->hasOne(Tedarikci::class, ['tedarikci_kodu' => 'tedarikci_kodu']);
    }
    
    /**
     * Magic method to handle branch quantity attributes
     * @param string $name
     * @return mixed
     */
    public function __get($name)
    {
        if (strpos($name, 'branch_qty_') === 0) {
            $branchId = str_replace('branch_qty_', '', $name);
            return $this->_branchQuantities[$branchId] ?? 0;
        }
        if (strpos($name, 'branch_one_month_') === 0) {
            $branchId = str_replace('branch_one_month_', '', $name);
            return $this->_branchOneMonthSales[$branchId] ?? 0;
        }
        if (strpos($name, 'branch_sv_') === 0 || strpos($name, 'branch_velocity_') === 0) {
            $branchId = str_replace(['branch_sv_', 'branch_velocity_'], '', $name);
            return $this->_branchVelocities[$branchId] ?? 0;
        }
        if (strpos($name, 'branch_unit_') === 0) {
            $branchId = str_replace('branch_unit_', '', $name);
            return $this->_branchUnits[$branchId] ?? '';
        }
        return parent::__get($name);
    }
    
    /**
     * Magic method to handle branch quantity attributes
     * @param string $name
     * @param mixed $value
     */
    public function __set($name, $value)
    {
        if (strpos($name, 'branch_qty_') === 0) {
            $branchId = str_replace('branch_qty_', '', $name);
            $this->_branchQuantities[$branchId] = $value;
        } elseif (strpos($name, 'branch_one_month_') === 0) {
            $branchId = str_replace('branch_one_month_', '', $name);
            $this->_branchOneMonthSales[$branchId] = $value;
        } elseif (strpos($name, 'branch_sv_') === 0 || strpos($name, 'branch_velocity_') === 0) {
            $branchId = str_replace(['branch_sv_', 'branch_velocity_'], '', $name);
            $this->_branchVelocities[$branchId] = $value;
        } elseif (strpos($name, 'branch_unit_') === 0) {
            $branchId = str_replace('branch_unit_', '', $name);
            $this->_branchUnits[$branchId] = $value;
        } else {
            parent::__set($name, $value);
        }
    }
    
    /**
     * Magic method to check if attribute exists
     * @param string $name
     * @return bool
     */
    public function __isset($name)
    {
        if (strpos($name, 'branch_qty_') === 0) {
            return true;
        }
        if (strpos($name, 'branch_one_month_') === 0) {
            return true;
        }
        if (strpos($name, 'branch_sv_') === 0 || strpos($name, 'branch_velocity_') === 0) {
            return true;
        }
        if (strpos($name, 'branch_unit_') === 0) {
            return true;
        }
        return parent::__isset($name);
    }
}
