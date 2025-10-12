<?php

namespace app\models;

use Yii;
use yii\db\ActiveRecord;

/**
 * This is the model class for table "file_imports"
 * 
 * @property int $id
 * @property string $file_name
 * @property string $original_name
 * @property string $status
 * @property int $total_rows
 * @property int $processed_rows
 * @property string $last_processed_at
 * @property string $created_at
 * @property string $error_log
 */
class FileImport extends ActiveRecord
{
    const STATUS_PENDING = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_COMPLETED = 'completed';
    const STATUS_FAILED = 'failed';

    public static function tableName()
    {
        return 'file_imports';
    }

    public function rules()
    {
        return [
            [['file_name', 'original_name'], 'required'],
            [['status'], 'string'],
            [['total_rows', 'processed_rows'], 'integer'],
            [['last_processed_at', 'created_at'], 'safe'],
            [['error_log'], 'string'],
        ];
    }
}