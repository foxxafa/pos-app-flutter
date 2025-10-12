<?php

namespace app\models;

use Yii;
use yii\db\ActiveRecord;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;

/**
 * This is the model class for table "counting_slips".
 *
 * @property int $id
 * @property string $slip_no
 * @property string $warehouse_code
 * @property string|null $dia_fisno
 * @property string|null $dia_sayimfisi_key
 * @property string|null $dia_response
 * @property string $status
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $_key
 * @property boolean $active
 * @property int $created_by
 */
class CountingSlips extends ActiveRecord
{
    const STATUS_PENDING = 'pending';
    const STATUS_SENT = 'sent';
    const STATUS_ERROR = 'error';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'counting_slips';
    }

    /**
     * {@inheritdoc}
     */
    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'), // Veritabanı uyumluluğu için
            ],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['warehouse_code'], 'required'],
            [['dia_response', 'status', '_key'], 'string'],
            [['created_at', 'updated_at'], 'safe'],
            [['slip_no', 'dia_fisno', 'dia_sayimfisi_key'], 'string', 'max' => 100],
            [['warehouse_code', '_key'], 'string', 'max' => 45],
            [['slip_no'], 'unique'],
            ['status', 'default', 'value' => self::STATUS_PENDING],
            ['status', 'in', 'range' => [self::STATUS_PENDING, self::STATUS_SENT, self::STATUS_ERROR]],
            [['active'], 'integer'],
            ['active', 'default', 'value' => true],
            [['created_by'], 'integer'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'slip_no' => 'Fiş No',
            'warehouse_code' => 'Depo Kodu',
            'dia_fisno' => 'Dia Fiş No',
            'dia_sayimfisi_key' => 'Dia Sayım Fişi Key',
            'dia_response' => 'Dia Cevabı',
            'status' => 'Durum',
            'created_at' => 'Oluşturma Tarihi',
            'updated_at' => 'Güncelleme Tarihi',
            '_key' => 'Key',
            'active' => 'Aktif',
            'created_by' => 'Oluşturan Kullanıcı',
        ];
    }

    /**
     * @inheritdoc
     */
    public function afterSave($insert, $changedAttributes)
    {
        parent::afterSave($insert, $changedAttributes);
        if ($insert) {
            $this->slip_no = 'WS' . str_pad($this->id, 6, '0', STR_PAD_LEFT);
            $this->updateAttributes(['slip_no']);
        }
    }
}
